import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'database.dart';
import 'search_index.dart';
import 'snapshot.dart';

/// When a bundled hymn book was built, read from the small `content.json` written next
/// to it, so the app can spot a newer bundle without opening the database.
class BundleVersion {
  const BundleVersion(this.builtAt, this.schemaVersion);

  factory BundleVersion.parse(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    return BundleVersion(
      DateTime.parse(json['builtAt']! as String),
      json['schemaVersion']! as int,
    );
  }

  final DateTime builtAt;
  final int schemaVersion;

  Map<String, Object?> toJson() => {
    'builtAt': builtAt.toUtc().toIso8601String(),
    'schemaVersion': schemaVersion,
  };
}

/// The `content.json` that goes next to [databasePath].
String versionFileFor(String databasePath) =>
    p.join(p.dirname(databasePath), 'content.json');

/// Writes a complete hymn book to [outPath]: the content of [snapshot], its search
/// index and the bundle info, plus the `content.json` beside it.
Future<ImportSummary> buildContentDatabase(
  ContentSnapshot snapshot, {
  required String outPath,
  required DateTime builtAt,
  required String source,
}) async {
  final out = File(outPath);
  await out.parent.create(recursive: true);
  for (final old in [out, File('$outPath-journal')]) {
    if (old.existsSync()) old.deleteSync();
  }
  final db = ContentDatabase(NativeDatabase(out));
  try {
    final summary = await importSnapshot(db, snapshot);
    await rebuildSearchIndex(db);
    await db
        .into(db.bundleInfo)
        .insert(
          BundleInfoCompanion.insert(
            id: const Value(1),
            builtAt: builtAt.toUtc(),
            source: source,
            schemaVersion: ContentDatabase.version,
          ),
        );
    await db.customStatement('VACUUM');
    await File(versionFileFor(outPath)).writeAsString(
      jsonEncode(BundleVersion(builtAt, ContentDatabase.version).toJson()),
    );
    return summary;
  } finally {
    await db.close();
  }
}
