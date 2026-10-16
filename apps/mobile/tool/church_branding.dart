import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Turns a church's branding into its Android launcher icons (ADR 0007).
///
/// From `apps/mobile`: `dart run tool/church_branding.dart ../../churches/<slug>`.
/// It reads `branding/icon.png`, `icon_foreground.png` and `icon_monochrome.png` and the
/// church's `BRAND_PRIMARY`, and writes `android/res` in the church's folder. Gradle adds
/// that folder to builds made with the church's settings file. Like the rest of the
/// folder, it stays on the build machine.
void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/church_branding.dart <church folder>, '
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

/// The legacy icon (Android 7) is 48 dp; adaptive icon layers are 108 dp. The logo on
/// the launch screen of Android before 12 is 240 dp, the size Android 12 and later draw
/// the icon on their splash; the wordmark under it is 200 x 80 dp, their branding size.
const _legacyDp = 48;
const _layerDp = 108;
const _splashLogoDp = 240;
const _wordmarkDp = (width: 200, height: 80);

/// The largest square file written, the splash logo at xxxhdpi: smaller images would
/// be blown up.
const _minimumSize = _splashLogoDp * 4;

const _adaptiveIcon = '''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
''';

/// Writes [church]'s launcher icons and launch screen into `<church>/android/res`,
/// replacing any earlier output, and returns how many files it wrote.
int writeAndroidBranding(Directory church) {
  final brand = _brandPrimary(church);
  final icon = _readSquare(church, 'icon.png');
  final foreground = _readSquare(church, 'icon_foreground.png');
  final monochrome = _readSquare(church, 'icon_monochrome.png');
  final wordmark = _readWordmark(church);

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

  void writeSizes(String name, img.Image image, int widthDp, int heightDp) {
    final weighted = _weightByOpacity(image);
    for (final MapEntry(key: density, value: scale) in _densities.entries) {
      final small = _shrink(
        weighted,
        (widthDp * scale).round(),
        (heightDp * scale).round(),
        opaque: image.numChannels == 3,
      );
      final [folder, file] = name.split('/');
      write('$folder-$density/$file', img.encodePng(small));
    }
  }

  writeSizes('mipmap/ic_launcher.png', legacy, _legacyDp, _legacyDp);
  writeSizes(
    'mipmap/ic_launcher_foreground.png',
    foreground,
    _layerDp,
    _layerDp,
  );
  writeSizes(
    'mipmap/ic_launcher_monochrome.png',
    monochrome,
    _layerDp,
    _layerDp,
  );
  writeSizes(
    'drawable/splash_logo.png',
    foreground,
    _splashLogoDp,
    _splashLogoDp,
  );
  if (wordmark != null) {
    writeSizes(
      'drawable/splash_branding.png',
      wordmark,
      _wordmarkDp.width,
      _wordmarkDp.height,
    );
  }
  write('mipmap-anydpi-v26/ic_launcher.xml', utf8.encode(_adaptiveIcon));
  write(
    'values/church_colors.xml',
    utf8.encode(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<resources>\n'
      '    <color name="ic_launcher_background">${brand.hex}</color>\n'
      '    <color name="splash_background">${brand.hex}</color>\n'
      '</resources>\n',
    ),
  );
  // Android before 12 shows this while the app starts; Android 12 and later draw the
  // icon on splash_background and the wordmark from their own theme (styles.xml).
  write(
    'drawable-v21/launch_background.xml',
    utf8.encode(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n'
      '    <item android:drawable="@color/splash_background" />\n'
      '    <item>\n'
      '        <bitmap android:gravity="center" android:src="@drawable/splash_logo" />\n'
      '    </item>\n'
      '${wordmark == null ? '' : '    <item android:bottom="48dp">\n'
                '        <bitmap android:gravity="bottom|center_horizontal"\n'
                '            android:src="@drawable/splash_branding" />\n'
                '    </item>\n'}'
      '</layer-list>\n',
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

/// The optional wordmark under the splash logo, `branding/splash_branding.png`: white
/// on transparent, 800 x 320 (200 x 80 dp at xxxhdpi), or larger in the same 5:2 shape.
img.Image? _readWordmark(Directory church) {
  final file = File('${church.path}/branding/splash_branding.png');
  if (!file.existsSync()) return null;
  final image = img.decodePng(file.readAsBytesSync());
  if (image == null) {
    throw BrandingException('${file.path} is not a PNG image.');
  }
  final wide = _wordmarkDp.width * 4;
  final high = _wordmarkDp.height * 4;
  if (image.width < wide || image.width * high != image.height * wide) {
    throw BrandingException(
      '${file.path} must be ${wide}x$high (or larger in the same 5:2 shape), '
      'not ${image.width}x${image.height}.',
    );
  }
  return image.convert(format: img.Format.uint8, numChannels: 4);
}

/// [image] with each colour multiplied by its opacity, ready for [_shrink]. Averaging
/// these keeps artwork its own colour where it fades into transparency.
img.Image _weightByOpacity(img.Image image) {
  final weighted = image.convert(format: img.Format.uint8, numChannels: 4);
  for (final p in weighted) {
    final opacity = p.a / 255;
    p
      ..r = (p.r * opacity).round()
      ..g = (p.g * opacity).round()
      ..b = (p.b * opacity).round();
  }
  return weighted;
}

/// [weighted] (from [_weightByOpacity]) shrunk to [width] x [height], with its colours
/// restored; without an alpha channel when the source was [opaque].
img.Image _shrink(
  img.Image weighted,
  int width,
  int height, {
  required bool opaque,
}) {
  final small = img.copyResize(
    weighted,
    width: width,
    height: height,
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
  return opaque ? small.convert(numChannels: 3) : small;
}
