import 'dart:io';

import 'package:content_db/content_db.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

const _bundledDatabase = 'assets/content/content.db';
const _bundledVersion = 'assets/content/content.json';

/// Installs or updates the bundled hymn book on the phone (spec section 6.2) and opens
/// it. Throws [NotEnoughSpaceException] when the phone is full.
Future<ContentDatabase> openBundledContent() async {
  final support = await getApplicationSupportDirectory();
  final temp = await getTemporaryDirectory();
  // Android forbids /tmp, where SQLite would otherwise put temporary files.
  sqlite3.tempDirectory = temp.path;
  final path = p.join(support.path, 'content.db');
  final version = BundleVersion.parse(
    await rootBundle.loadString(_bundledVersion),
  );
  await ContentInstaller(path).ensureInstalled(
    bundledBuiltAt: version.builtAt,
    loadBundle: () async {
      final data = await rootBundle.load(_bundledDatabase);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    },
  );
  return ContentDatabase(NativeDatabase.createInBackground(File(path)));
}
