import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/church_branding.dart';

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
const _splashLogoSizes = {
  'mdpi': 240,
  'hdpi': 360,
  'xhdpi': 480,
  'xxhdpi': 720,
  'xxxhdpi': 960,
};
const _wordmarkSizes = {
  'mdpi': (200, 80),
  'hdpi': (300, 120),
  'xhdpi': (400, 160),
  'xxhdpi': (600, 240),
  'xxxhdpi': (800, 320),
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
    church = Directory.systemTemp.createTempSync('church_branding_test');
    Directory(path('branding')).createSync();
    writeBrand('#24426b');
    writePng('icon.png', _icon(1024));
    writePng('icon_foreground.png', _artwork(1024));
    writePng('icon_monochrome.png', _artwork(1024));
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
      File(path('android/res/values/church_colors.xml')).readAsStringSync(),
      contains('<color name="ic_launcher_background">#24426B</color>'),
    );
  });

  test('gives the splash the brand colour', () {
    writeAndroidBranding(church);

    expect(
      File(path('android/res/values/church_colors.xml')).readAsStringSync(),
      contains('<color name="splash_background">#24426B</color>'),
    );
  });

  test('centres the logo on the launch screen of older Android', () {
    writeAndroidBranding(church);

    final launch = File(
      path('android/res/drawable-v21/launch_background.xml'),
    ).readAsStringSync();
    expect(launch, contains('@color/splash_background'));
    expect(launch, contains('@drawable/splash_logo'));
    for (final MapEntry(key: density, value: size)
        in _splashLogoSizes.entries) {
      final logo = readPng('android/res/drawable-$density/splash_logo.png');
      expect((logo.width, logo.height), (size, size), reason: density);
    }
  });

  test('adds the wordmark to the splash when the church has one', () {
    writePng('splash_branding.png', _artwork(800, 320));

    writeAndroidBranding(church);

    expect(
      File(
        path('android/res/drawable-v21/launch_background.xml'),
      ).readAsStringSync(),
      contains('@drawable/splash_branding'),
    );
    for (final MapEntry(key: density, value: (width, height))
        in _wordmarkSizes.entries) {
      final wordmark = readPng(
        'android/res/drawable-$density/splash_branding.png',
      );
      expect((wordmark.width, wordmark.height), (width, height));
    }
  });

  test('leaves the wordmark out when the church has none', () {
    writeAndroidBranding(church);

    expect(
      File(
        path('android/res/drawable-v21/launch_background.xml'),
      ).readAsStringSync(),
      isNot(contains('splash_branding')),
    );
    expect(
      File(path('android/res/drawable-mdpi/splash_branding.png')).existsSync(),
      isFalse,
    );
  });

  test('refuses a wordmark that is not 5:2', () {
    writePng('splash_branding.png', _artwork(800, 400));

    expect(() => writeAndroidBranding(church), failsWith('800x320'));
  });

  test('refuses a wordmark smaller than 800x320', () {
    writePng('splash_branding.png', _artwork(400, 160));

    expect(() => writeAndroidBranding(church), failsWith('800x320'));
  });

  test('cuts the Home logo as a disc from the middle of the icon', () {
    writeAppLogo(church, Directory(path('assets')));

    final logo = readPng('assets/church_logo.png');
    expect((logo.width, logo.height), (192, 192));
    final centre = logo.getPixel(96, 96);
    expect((centre.r, centre.g, centre.b, centre.a), (0x24, 0x42, 0x6b, 255));
    expect(logo.getPixel(2, 2).a, 0, reason: 'a corner is outside the disc');
    expect(logo.getPixel(20, 20).a, 0, reason: 'still outside the disc');
    expect(
      logo.getPixel(3, 96).a,
      greaterThan(0),
      reason: 'the disc is full width',
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
    writePng('icon.png', _icon(1024, 800));

    expect(() => writeAndroidBranding(church), failsWith('square'));
  });

  test('refuses an image smaller than the largest file made from it', () {
    writePng('icon_foreground.png', _artwork(600));

    expect(() => writeAndroidBranding(church), failsWith('960'));
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

/// A white rectangle in the middle third of a clear canvas.
img.Image _artwork(int width, [int? height]) {
  final h = height ?? width;
  final image = img.Image(width: width, height: h, numChannels: 4);
  img.fillRect(
    image,
    x1: width ~/ 3,
    y1: h ~/ 3,
    x2: 2 * width ~/ 3,
    y2: 2 * h ~/ 3,
    color: img.ColorRgba8(255, 255, 255, 255),
  );
  return image;
}
