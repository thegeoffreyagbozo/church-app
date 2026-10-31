import 'dart:io';
import 'dart:typed_data';

import 'package:content_db/content_db.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late Directory dir;
  late String phonePath;
  late ContentInstaller installer;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('content_db_install');
    phonePath = '${dir.path}/phone/content.db';
    Directory('${dir.path}/phone').createSync();
    installer = ContentInstaller(phonePath);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// Builds a bundle from the sample, optionally keeping only the first [hymns] hymns.
  Future<Uint8List> bundle(DateTime builtAt, {int? hymns}) async {
    final sample = loadSample();
    final snapshot = ContentSnapshot(
      hymnals: sample.hymnals,
      categories: sample.categories,
      hymns: hymns == null ? sample.hymns : sample.hymns.take(hymns).toList(),
      sections: sample.sections,
      readings: sample.readings,
      parts: sample.parts,
      church: sample.church,
    );
    final out = '${dir.path}/bundle-${builtAt.millisecondsSinceEpoch}.db';
    await buildContentDatabase(
      snapshot,
      outPath: out,
      builtAt: builtAt,
      source: 'test',
    );
    return File(out).readAsBytesSync();
  }

  Future<T> withPhoneDb<T>(Future<T> Function(ContentDatabase db) use) async {
    final db = ContentDatabase(NativeDatabase(File(phonePath)));
    try {
      return await use(db);
    } finally {
      await db.close();
    }
  }

  final october = DateTime.utc(2026, 10, 1);
  final november = DateTime.utc(2026, 11, 1);

  test('copies the bundle on first launch', () async {
    final bytes = await bundle(october);

    final outcome = await installer.ensureInstalled(
      bundledBuiltAt: october,
      loadBundle: () async => bytes,
    );

    expect(outcome, InstallOutcome.installed);
    expect(await withPhoneDb((db) => ContentCatalog(db).builtAt()), october);
  });

  test('leaves the same bundle alone without loading it', () async {
    final bytes = await bundle(october);
    await installer.ensureInstalled(
      bundledBuiltAt: october,
      loadBundle: () async => bytes,
    );

    final outcome = await installer.ensureInstalled(
      bundledBuiltAt: october,
      loadBundle: () => fail('the bundle should not be loaded'),
    );

    expect(outcome, InstallOutcome.unchanged);
  });

  test(
    'a newer bundle replaces the content and keeps settings and recents',
    () async {
      final first = await bundle(october, hymns: 2);
      await installer.ensureInstalled(
        bundledBuiltAt: october,
        loadBundle: () async => first,
      );
      await withPhoneDb((db) async {
        await UserData(db).saveSetting('theme', 'night');
        await UserData(db).markOpened(ItemType.hymn, 'hymn-41');
      });
      final second = await bundle(november);

      final outcome = await installer.ensureInstalled(
        bundledBuiltAt: november,
        loadBundle: () async => second,
      );

      expect(outcome, InstallOutcome.updated);
      await withPhoneDb((db) async {
        expect(await db.select(db.hymns).get(), hasLength(8));
        expect(await UserData(db).settings(), {'theme': 'night'});
        final recent = await ContentCatalog(db).recentlyOpened();
        expect(recent.single.id, 'hymn-41');
      });
    },
  );

  test(
    'replaces a copy from before the church tagline, keeping settings',
    () async {
      final book = await bundle(october);
      await installer.ensureInstalled(
        bundledBuiltAt: october,
        loadBundle: () async => book,
      );
      await withPhoneDb((db) => UserData(db).saveSetting('theme', 'night'));
      // The phone's copy as schema 1 built it: no tagline column.
      sqlite3.open(phonePath)
        ..execute('ALTER TABLE church DROP COLUMN tagline')
        ..execute('PRAGMA user_version = 1')
        ..close();

      final outcome = await installer.ensureInstalled(
        bundledBuiltAt: october,
        loadBundle: () async => book,
      );

      expect(outcome, InstallOutcome.updated);
      await withPhoneDb((db) async {
        expect((await ContentCatalog(db).church())!.name, 'Grace Chapel');
        expect(await UserData(db).settings(), {'theme': 'night'});
      });
    },
  );

  test(
    'replaces a copy from before drawn notation, keeping settings',
    () async {
      final book = await bundle(october);
      await installer.ensureInstalled(
        bundledBuiltAt: october,
        loadBundle: () async => book,
      );
      await withPhoneDb((db) => UserData(db).saveSetting('theme', 'night'));
      // The phone's copy as schema 4 built it: no hymn_notation table.
      sqlite3.open(phonePath)
        ..execute('DROP TABLE hymn_notation')
        ..execute('PRAGMA user_version = 4')
        ..close();

      final outcome = await installer.ensureInstalled(
        bundledBuiltAt: october,
        loadBundle: () async => book,
      );

      expect(outcome, InstallOutcome.updated);
      await withPhoneDb((db) async {
        expect((await ContentCatalog(db).hymn('hymn-1'))!.notationVerses, 0);
        expect(await UserData(db).settings(), {'theme': 'night'});
      });
    },
  );

  test('replaces a damaged file', () async {
    File(phonePath).writeAsStringSync('this is not a database' * 100);
    final bytes = await bundle(october);

    final outcome = await installer.ensureInstalled(
      bundledBuiltAt: october,
      loadBundle: () async => bytes,
    );

    expect(outcome, InstallOutcome.repaired);
    expect(await withPhoneDb((db) => ContentCatalog(db).builtAt()), october);
  });

  test('reports a full phone', () async {
    final full = ContentInstaller(
      phonePath,
      writeBytes: (file, bytes) async => throw FileSystemException(
        'Write failed',
        file.path,
        const OSError('No space left on device', 28),
      ),
    );

    expect(
      full.ensureInstalled(
        bundledBuiltAt: october,
        loadBundle: () async => Uint8List(0),
      ),
      throwsA(isA<NotEnoughSpaceException>()),
    );
  });

  test('an update on a full phone keeps the book already there', () async {
    final first = await bundle(october);
    await installer.ensureInstalled(
      bundledBuiltAt: october,
      loadBundle: () async => first,
    );
    final second = await bundle(november);
    // The storage fills up halfway through writing the new copy.
    final full = ContentInstaller(
      phonePath,
      writeBytes: (file, bytes) async {
        await file.writeAsBytes(bytes.sublist(0, bytes.length ~/ 2));
        throw FileSystemException(
          'Write failed',
          file.path,
          const OSError('No space left on device', 28),
        );
      },
    );

    final outcome = await full.ensureInstalled(
      bundledBuiltAt: november,
      loadBundle: () async => second,
    );

    expect(outcome, InstallOutcome.unchanged);
    expect(await withPhoneDb((db) => ContentCatalog(db).builtAt()), october);
    expect(File('$phonePath.new').existsSync(), isFalse);
  });
}
