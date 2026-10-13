import 'dart:io';

import 'package:content_db/content_db.dart';
import 'package:drift/native.dart';

/// The public-domain sample content used across the tests.
ContentSnapshot loadSample() => ContentSnapshot.parse(
  File('test/fixtures/sample_content.json').readAsStringSync(),
);

/// An in-memory database holding the sample, with its search index built.
Future<ContentDatabase> sampleDatabase() async {
  final db = ContentDatabase(NativeDatabase.memory());
  await importSnapshot(db, loadSample());
  await rebuildSearchIndex(db);
  return db;
}
