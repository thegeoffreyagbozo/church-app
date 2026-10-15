import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Turns a church's branding into its Android launcher icons (ADR 0007).
///
/// From `apps/mobile`: `dart run tool/android_branding.dart ../../churches/<slug>`.
/// It reads `branding/icon.png`, `icon_foreground.png` and `icon_monochrome.png` and the
/// church's `BRAND_PRIMARY`, and writes `android/res` in the church's folder. Gradle adds
/// that folder to builds made with the church's settings file. Like the rest of the
/// folder, it stays on the build machine.
void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/android_branding.dart <church folder>, '
      'such as ../../churches/example',
    );
    exit(64);
  }
  final church = Directory(arguments.single);
  try {
    final written = writeAndroidBranding(church);
    stdout.writeln('Wrote ${church.path}/android/res: $written files.');
  } on BrandingException catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }
}

/// A church's branding can't be turned into icons; [message] says what to fix.
class BrandingException implements Exception {
  const BrandingException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

/// The legacy icon (Android 7) is 48 dp; adaptive icon layers are 108 dp.
const _legacyDp = 48;
const _layerDp = 108;

/// The largest file written, a layer at xxxhdpi: smaller images would be blown up.
const _minimumSize = _layerDp * 4;

const _adaptiveIcon = '''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
''';

/// Writes [church]'s launcher icons into `<church>/android/res`, replacing any earlier
/// output, and returns how many files it wrote.
int writeAndroidBranding(Directory church) {
  final brand = _brandPrimary(church);
  final icon = _readSquare(church, 'icon.png');
  final foreground = _readSquare(church, 'icon_foreground.png');
  final monochrome = _readSquare(church, 'icon_monochrome.png');

  // Launchers before Android 8 show the icon as it is, so fill any transparency with the
  // brand colour, the same colour as the adaptive icon's background.
  final legacy = img.Image(width: icon.width, height: icon.height)
    ..clear(img.ColorRgb8(brand.r, brand.g, brand.b));
  img.compositeImage(legacy, icon);

  final res = Directory('${church.path}/android/res');
  if (res.existsSync()) res.deleteSync(recursive: true);

  var written = 0;
  void write(String relative, List<int> bytes) {
    File('${res.path}/$relative')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    written++;
  }

  for (final MapEntry(key: density, value: scale) in _densities.entries) {
    final legacySize = (_legacyDp * scale).round();
    final layerSize = (_layerDp * scale).round();
    write(
      'mipmap-$density/ic_launcher.png',
      img.encodePng(_shrink(legacy, legacySize)),
    );
    write(
      'mipmap-$density/ic_launcher_foreground.png',
      img.encodePng(_shrink(foreground, layerSize)),
    );
    write(
      'mipmap-$density/ic_launcher_monochrome.png',
      img.encodePng(_shrink(monochrome, layerSize)),
    );
  }
  write('mipmap-anydpi-v26/ic_launcher.xml', utf8.encode(_adaptiveIcon));
  write(
    'values/ic_launcher_background.xml',
    utf8.encode(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<resources>\n'
      '    <color name="ic_launcher_background">${brand.hex}</color>\n'
      '</resources>\n',
    ),
  );
  return written;
}

/// `BRAND_PRIMARY` from the church's settings file, as `#RRGGBB`.
({int r, int g, int b, String hex}) _brandPrimary(Directory church) {
  final file = File('${church.path}/church.json');
  if (!file.existsSync()) {
    throw BrandingException('${file.path} is missing.');
  }
  final value = (jsonDecode(file.readAsStringSync()) as Map)['BRAND_PRIMARY'];
  final match = RegExp(
    r'^#([0-9A-Fa-f]{6})$',
  ).firstMatch(value is String ? value.trim() : '');
  if (match == null) {
    throw BrandingException(
      'BRAND_PRIMARY in ${file.path} must be a colour like #24426B, '
      'not ${jsonEncode(value)}.',
    );
  }
  final rgb = int.parse(match.group(1)!, radix: 16);
  return (
    r: rgb >> 16 & 0xff,
    g: rgb >> 8 & 0xff,
    b: rgb & 0xff,
    hex: '#${match.group(1)!.toUpperCase()}',
  );
}

/// A branding image as 8-bit RGBA, checked to be square and large enough.
img.Image _readSquare(Directory church, String name) {
  final file = File('${church.path}/branding/$name');
  if (!file.existsSync()) {
    throw BrandingException(
      '${file.path} is missing (see churches/README.md for the branding files).',
    );
  }
  final image = img.decodePng(file.readAsBytesSync());
  if (image == null) {
    throw BrandingException('${file.path} is not a PNG image.');
  }
  if (image.width != image.height) {
    throw BrandingException(
      '${file.path} must be square, not ${image.width}x${image.height}.',
    );
  }
  if (image.width < _minimumSize) {
    throw BrandingException(
      '${file.path} must be at least ${_minimumSize}x$_minimumSize, '
      'not ${image.width}x${image.height}; export it at 1024x1024.',
    );
  }
  return image.convert(format: img.Format.uint8, numChannels: 4);
}

/// [image] shrunk to [size] square. Colours are averaged weighted by their opacity, so
/// artwork keeps its colour where it fades into transparency instead of greying.
img.Image _shrink(img.Image image, int size) {
  final weighted = image.convert(format: img.Format.uint8, numChannels: 4);
  for (final p in weighted) {
    final opacity = p.a / 255;
    p
      ..r = (p.r * opacity).round()
      ..g = (p.g * opacity).round()
      ..b = (p.b * opacity).round();
  }
  final small = img.copyResize(
    weighted,
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  );
  for (final p in small) {
    if (p.a == 0) continue;
    final opacity = p.a / 255;
    p
      ..r = (p.r / opacity).round().clamp(0, 255)
      ..g = (p.g / opacity).round().clamp(0, 255)
      ..b = (p.b / opacity).round().clamp(0, 255);
  }
  return image.numChannels == 3 ? small.convert(numChannels: 3) : small;
}
