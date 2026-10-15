import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/android_branding.dart';

const _legacySizes = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};
const _layerSizes = {
  'mdpi': 108,
  'hdpi': 162,
  'xhdpi': 216,
  'xxhdpi': 324,
  'xxxhdpi': 432,
};

void main() {
  late Directory church;

  String path(String relative) => '${church.path}/$relative';
  img.Image readPng(String relative) =>
      img.decodePng(File(path(relative)).readAsBytesSync())!;
  void writePng(String name, img.Image image) =>
      File(path('branding/$name')).writeAsBytesSync(img.encodePng(image));
  void writeBrand(String colour) => File(
    path('church.json'),
  ).writeAsStringSync(jsonEncode({'BRAND_PRIMARY': colour}));
  Matcher failsWith(String text) => throwsA(
    isA<BrandingException>().having(
      (e) => e.message,
      'message',
      contains(text),
    ),
  );

  setUp(() {
    church = Directory.systemTemp.createTempSync('android_branding_test');
    Directory(path('branding')).createSync();
    writeBrand('#24426b');
    writePng('icon.png', _icon(512));
    writePng('icon_foreground.png', _artwork(512));
    writePng('icon_monochrome.png', _artwork(512));
  });
  tearDown(() => church.deleteSync(recursive: true));

  test('writes the legacy launcher icon at 48 dp for every density', () {
    writeAndroidBranding(church);

    for (final MapEntry(key: density, value: size) in _legacySizes.entries) {
      final icon = readPng('android/res/mipmap-$density/ic_launcher.png');
      expect((icon.width, icon.height), (size, size), reason: density);
      expect(icon.numChannels, 3, reason: '$density has no alpha');
    }
  });

  test('fills the legacy icon\'s transparent corner with the brand colour', () {
    writeAndroidBranding(church);

    final corner = readPng(
      'android/res/mipmap-xxxhdpi/ic_launcher.png',
    ).getPixel(2, 2);
    expect((corner.r, corner.g, corner.b), (0x24, 0x42, 0x6b));
  });

  test('writes the adaptive layers at 108 dp, keeping their transparency', () {
    writeAndroidBranding(church);

    for (final layer in ['ic_launcher_foreground', 'ic_launcher_monochrome']) {
      for (final MapEntry(key: density, value: size) in _layerSizes.entries) {
        final image = readPng('android/res/mipmap-$density/$layer.png');
        expect((image.width, image.height), (size, size), reason: layer);
        expect(image.getPixel(0, 0).a, 0, reason: '$layer corner is clear');
      }
    }
  });

  test('keeps the artwork\'s edge colour when shrinking a layer', () {
    writeAndroidBranding(church);

    final layer = readPng('android/res/mipmap-mdpi/ic_launcher_foreground.png');
    // Read the colours while iterating: the image reuses one pixel object.
    final edges = [
      for (final p in layer)
        if (p.a > 0 && p.a < 255) (p.r, p.g, p.b),
    ];
    expect(edges, isNotEmpty, reason: 'the white square has soft edges');
    expect(edges, everyElement((255, 255, 255)));
  });

  test('points the adaptive icon at its layers and the brand colour', () {
    writeAndroidBranding(church);

    final adaptive = File(
      path('android/res/mipmap-anydpi-v26/ic_launcher.xml'),
    ).readAsStringSync();
    expect(adaptive, contains('@color/ic_launcher_background'));
    expect(adaptive, contains('@mipmap/ic_launcher_foreground'));
    expect(adaptive, contains('@mipmap/ic_launcher_monochrome'));
    expect(
      File(
        path('android/res/values/ic_launcher_background.xml'),
      ).readAsStringSync(),
      contains('<color name="ic_launcher_background">#24426B</color>'),
    );
  });

  test('replaces what an earlier run left behind', () {
    final stale = File(path('android/res/mipmap-mdpi/old.png'))
      ..createSync(recursive: true);

    writeAndroidBranding(church);

    expect(stale.existsSync(), isFalse);
  });

  test('names a missing branding image', () {
    File(path('branding/icon_monochrome.png')).deleteSync();

    expect(
      () => writeAndroidBranding(church),
      failsWith('icon_monochrome.png'),
    );
  });

  test('refuses an image that is not square', () {
    writePng('icon.png', _icon(512, 400));

    expect(() => writeAndroidBranding(church), failsWith('square'));
  });

  test('refuses an image smaller than the largest layer', () {
    writePng('icon_foreground.png', _artwork(300));

    expect(() => writeAndroidBranding(church), failsWith('432'));
  });

  test('refuses a brand colour that is not #RRGGBB', () {
    writeBrand('navy');

    expect(() => writeAndroidBranding(church), failsWith('BRAND_PRIMARY'));
  });
}

/// The brand colour with a transparent top-left quarter, as design tools export it.
img.Image _icon(int width, [int? height]) {
  final image = img.Image(
    width: width,
    height: height ?? width,
    numChannels: 4,
  );
  img.fill(image, color: img.ColorRgba8(0x24, 0x42, 0x6b, 255));
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: width ~/ 4,
    y2: (height ?? width) ~/ 4,
    color: img.ColorRgba8(0, 0, 0, 0),
    alphaBlend: false,
  );
  return image;
}

/// A white square in the middle third of a clear canvas.
img.Image _artwork(int size) {
  final image = img.Image(width: size, height: size, numChannels: 4);
  img.fillRect(
    image,
    x1: size ~/ 3,
    y1: size ~/ 3,
    x2: 2 * size ~/ 3,
    y2: 2 * size ~/ 3,
    color: img.ColorRgba8(255, 255, 255, 255),
  );
  return image;
}
