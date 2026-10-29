import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notation/src/resources.dart';

/// Serves one zip as the Verovio asset and counts how often it is read.
class _ZipBundle extends CachingAssetBundle {
  _ZipBundle(this.zip);

  final Uint8List zip;
  var loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    expect(key, verovioAsset);
    return ByteData.sublistView(zip);
  }
}

Uint8List _zipOf(Map<String, String> files) {
  final archive = Archive();
  files.forEach(
    (name, text) => archive.addFile(ArchiveFile.string(name, text)),
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('notation_'));
  tearDown(() => root.deleteSync(recursive: true));

  test('unpacks the fonts and returns the folder Verovio reads', () async {
    final bundle = _ZipBundle(
      _zipOf({'Leland.xml': '<font/>', 'Leland/E0A4.xml': '<g/>'}),
    );

    final path = await installResources(bundle, into: root);

    expect(File('$path/Leland.xml').readAsStringSync(), '<font/>');
    expect(File('$path/Leland/E0A4.xml').readAsStringSync(), '<g/>');
  });

  test(
    'a finished install is reused without reading the asset again',
    () async {
      final bundle = _ZipBundle(_zipOf({'Leland.xml': '<font/>'}));

      final first = await installResources(bundle, into: root);
      final second = await installResources(bundle, into: root);

      expect(second, first);
      expect(bundle.loads, 1);
    },
  );

  test('an install cut short (no marker) is done again', () async {
    final bundle = _ZipBundle(_zipOf({'Leland.xml': '<font/>'}));
    final path = await installResources(bundle, into: root);
    File('$path/$completeMarker').deleteSync();
    File('$path/Leland.xml').writeAsStringSync('half');

    await installResources(bundle, into: root);

    expect(File('$path/Leland.xml').readAsStringSync(), '<font/>');
    expect(bundle.loads, 2);
  });
}
