import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'database.dart';
import 'music_files.dart';
import 'png.dart';
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
/// index and the bundle info, plus the `content.json` beside it, and its sheet music
/// read from [musicFiles] into the `music` folder beside it.
Future<ImportSummary> buildContentDatabase(
  ContentSnapshot snapshot, {
  required String outPath,
  required DateTime builtAt,
  required String source,
  MusicFiles? musicFiles,
}) async {
  final out = File(outPath);
  await out.parent.create(recursive: true);
  for (final old in [out, File('$outPath-journal')]) {
    if (old.existsSync()) old.deleteSync();
  }
  final sizes = await writeMusicFiles(
    snapshot,
    musicDirFor(outPath),
    musicFiles,
  );
  final db = ContentDatabase(NativeDatabase(out));
  try {
    final summary = await importSnapshot(db, snapshot, musicSizes: sizes);
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

/// The folder beside [databasePath] that holds the bundled sheet music.
String musicDirFor(String databasePath) =>
    p.join(p.dirname(databasePath), 'music');

/// Replaces [dir] with the pieces [snapshot] bundles, read from [files], as
/// `<id>.png`, and returns each piece's size. Without [files] the folder is left
/// empty (the app then shows words where music would be).
Future<Map<String, ImageSize>> writeMusicFiles(
  ContentSnapshot snapshot,
  String dir,
  MusicFiles? files,
) async {
  final folder = Directory(dir);
  if (folder.existsSync()) folder.deleteSync(recursive: true);
  folder.createSync(recursive: true);
  final sizes = <String, ImageSize>{};
  if (files == null) return sizes;
  final pieces = bundledMusic(snapshot);
  for (var i = 0; i < pieces.length; i += 8) {
    await Future.wait([
      for (final r in pieces.skip(i).take(8))
        () async {
          final path = r['storage_path']! as String;
          final bytes = await files.read(
            r['storage_bucket'] as String? ?? 'sheet-music',
            path,
          );
          final size = pngSize(bytes);
          if (size == null) throw MusicFileException(path, 'not a PNG image');
          await File(p.join(dir, '${r['id']}.png')).writeAsBytes(bytes);
          sizes[r['id']! as String] = size;
        }(),
    ]);
  }
  return sizes;
}
