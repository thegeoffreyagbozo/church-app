import 'dart:io';
import 'dart:typed_data';

import 'package:content_db/content_db.dart';
import 'package:drift/native.dart';

/// The public-domain sample content used across the tests.
ContentSnapshot loadSample() => ContentSnapshot.parse(
  File('test/fixtures/sample_content.json').readAsStringSync(),
);

/// An in-memory database holding the sample, with its search index built.
Future<ContentDatabase> sampleDatabase() async {
  final db = ContentDatabase(NativeDatabase.memory());
  await importSnapshot(db, loadSample(), musicSizes: sampleMusicSizes);
  await rebuildSearchIndex(db);
  return db;
}

/// The start of a PNG file of [width] x [height]: enough for [pngSize].
Uint8List fakePng(int width, int height) {
  final bytes = ByteData(33);
  [137, 80, 78, 71, 13, 10, 26, 10].asMap().forEach(bytes.setUint8);
  bytes.setUint32(8, 13);
  'IHDR'.codeUnits.asMap().forEach((i, c) => bytes.setUint8(12 + i, c));
  bytes.setUint32(16, width);
  bytes.setUint32(20, height);
  return bytes.buffer.asUint8List();
}

/// Sizes for the sample's music pieces, as a build would read them.
const sampleMusicSizes = {
  'music-41-1': ImageSize(1200, 900),
  'music-41-2': ImageSize(1200, 500),
  'music-doxology-1': ImageSize(1200, 700),
};
