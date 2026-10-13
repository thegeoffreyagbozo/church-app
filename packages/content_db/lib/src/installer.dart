import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import 'database.dart';

/// What [ContentInstaller.ensureInstalled] did.
enum InstallOutcome {
  /// First launch: the bundled hymn book was copied onto the phone.
  installed,

  /// The bundled hymn book was newer: content replaced, settings and recents kept.
  updated,

  /// The phone already had this hymn book (or a newer one).
  unchanged,

  /// The copy on the phone was damaged and was replaced; its settings were lost.
  repaired,
}

/// The phone ran out of storage while setting up the hymn book.
class NotEnoughSpaceException implements Exception {
  const NotEnoughSpaceException();

  @override
  String toString() => 'NotEnoughSpaceException';
}

/// Writes [bytes] to [file], flushing them to storage.
typedef WriteBytes = Future<void> Function(File file, Uint8List bytes);

/// Makes sure the phone has the hymn book bundled with the app (spec section 6.2).
///
/// The bundle is only loaded when it's needed: on first launch, after damage, or when
/// it's newer than the copy on the phone. An update writes the new file beside the old
/// one, copies the phone-only tables across with `ATTACH`, then swaps the files.
class ContentInstaller {
  ContentInstaller(this.databasePath, {WriteBytes? writeBytes})
    : _write = writeBytes ?? _writeFile;

  final String databasePath;
  final WriteBytes _write;

  static const _noSpace = 28; // ENOSPC on Android and iOS
  static const _sqliteFull = 13; // SQLITE_FULL

  Future<InstallOutcome> ensureInstalled({
    required DateTime bundledBuiltAt,
    required Future<Uint8List> Function() loadBundle,
  }) async {
    try {
      if (!File(databasePath).existsSync()) {
        await _replaceWith(await loadBundle());
        return InstallOutcome.installed;
      }
      final local = _inspect();
      if (local == null) {
        await _replaceWith(await loadBundle());
        return InstallOutcome.repaired;
      }
      final sameSchema = local.schemaVersion == ContentDatabase.version;
      if (sameSchema && !bundledBuiltAt.isAfter(local.builtAt)) {
        return InstallOutcome.unchanged;
      }
      return await _update(await loadBundle())
          ? InstallOutcome.updated
          : InstallOutcome.unchanged;
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == _noSpace) {
        throw const NotEnoughSpaceException();
      }
      rethrow;
    } on SqliteException catch (e) {
      if (e.resultCode == _sqliteFull) throw const NotEnoughSpaceException();
      rethrow;
    }
  }

  /// When the copy on the phone was built, or null if it fails its checks.
  ({DateTime builtAt, int schemaVersion})? _inspect() {
    Database? db;
    try {
      db = sqlite3.open(databasePath, mode: OpenMode.readWrite);
      if (db.select('PRAGMA quick_check').first.columnAt(0) != 'ok') {
        return null;
      }
      final version = db.select('PRAGMA user_version').first.columnAt(0);
      final built = db.select('SELECT built_at FROM bundle_info WHERE id = 1');
      if (built.isEmpty) return null;
      return (
        builtAt: DateTime.parse(built.first.columnAt(0) as String),
        schemaVersion: version as int,
      );
    } on SqliteException {
      return null;
    } on FormatException {
      return null;
    } finally {
      db?.close();
    }
  }

  Future<void> _replaceWith(Uint8List bytes) async {
    final download = File('$databasePath.download');
    await _write(download, bytes);
    _deleteSidecars();
    await download.rename(databasePath);
  }

  /// Installs [bytes] keeping the phone-only tables. Returns false, leaving the
  /// current book in place, if they can't be carried across.
  Future<bool> _update(Uint8List bytes) async {
    final fresh = File('$databasePath.new');
    await _write(fresh, bytes);
    final db = sqlite3.open(fresh.path);
    var carried = false;
    try {
      db
        ..execute('ATTACH DATABASE ? AS old', [databasePath])
        ..execute('BEGIN')
        ..execute(
          'INSERT OR REPLACE INTO main.settings (key, value) '
          'SELECT key, value FROM old.settings',
        )
        ..execute(
          'INSERT OR REPLACE INTO main.recently_opened '
          '(item_type, item_id, opened_at) '
          'SELECT item_type, item_id, opened_at FROM old.recently_opened',
        )
        ..execute('COMMIT')
        ..execute('DETACH DATABASE old');
      carried = true;
    } on SqliteException catch (e) {
      if (e.resultCode == _sqliteFull) rethrow;
    } finally {
      db.close();
    }
    if (!carried) {
      fresh.deleteSync();
      return false;
    }
    _deleteSidecars();
    await fresh.rename(databasePath);
    return true;
  }

  void _deleteSidecars() {
    for (final suffix in ['-journal', '-wal', '-shm']) {
      final file = File('$databasePath$suffix');
      if (file.existsSync()) file.deleteSync();
    }
  }
}

Future<void> _writeFile(File file, Uint8List bytes) =>
    file.writeAsBytes(bytes, flush: true);
