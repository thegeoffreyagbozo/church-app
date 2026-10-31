import 'dart:convert';
import 'dart:io';

import 'package:content_db/content_db.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('content_db_build'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('writes a database with its bundle info and search index', () async {
    final out = '${dir.path}/assets/content.db';

    final summary = await buildContentDatabase(
      loadSample(),
      outPath: out,
      builtAt: DateTime.utc(2026, 10, 12, 9),
      source: 'example.supabase.co',
    );

    expect(summary.hymns, 8);
    final db = ContentDatabase(NativeDatabase(File(out)));
    addTearDown(db.close);
    final info = await db.select(db.bundleInfo).getSingle();
    expect(info.builtAt, DateTime.utc(2026, 10, 12, 9));
    expect(info.source, 'example.supabase.co');
    final hits = await db
        .customSelect(
          'SELECT item_id FROM search_index WHERE search_index MATCH ?',
          variables: [Variable('"cleft"*')],
        )
        .get();
    expect(hits.map((r) => r.read<String>('item_id')), contains('hymn-1'));
  });

  test('writes content.json beside the database', () async {
    final out = '${dir.path}/content.db';

    await buildContentDatabase(
      loadSample(),
      outPath: out,
      builtAt: DateTime.utc(2026, 10, 12, 9),
      source: 'test',
    );

    final version = BundleVersion.parse(
      File(versionFileFor(out)).readAsStringSync(),
    );
    expect(version.builtAt, DateTime.utc(2026, 10, 12, 9));
    expect(version.schemaVersion, ContentDatabase.version);
  });

  test('replaces an earlier build', () async {
    final out = '${dir.path}/content.db';
    File(out).writeAsStringSync('not a database');

    await buildContentDatabase(
      loadSample(),
      outPath: out,
      builtAt: DateTime.utc(2026, 10, 12),
      source: 'test',
    );

    final db = ContentDatabase(NativeDatabase(File(out)));
    addTearDown(db.close);
    expect(await db.select(db.readings).get(), hasLength(5));
  });

  test('bundles the music of the hymns in the book, as <id>.png', () async {
    final music = Directory('${dir.path}/bucket')..createSync();
    for (final (path, w, h) in [
      ('hymns/041-1.png', 1200, 900),
      ('hymns/041-2.png', 1200, 500),
      ('service-music/doxology-1.png', 1200, 700),
    ]) {
      File('${music.path}/$path')
        ..createSync(recursive: true)
        ..writeAsBytesSync(fakePng(w, h));
    }
    final out = '${dir.path}/content/content.db';
    Directory(musicDirFor(out)).createSync(recursive: true);
    File('${musicDirFor(out)}/stale.png').writeAsStringSync('old');

    final summary = await buildContentDatabase(
      loadSample(),
      outPath: out,
      builtAt: DateTime.utc(2026, 10, 17),
      source: 'test',
      musicFiles: DirectoryMusicFiles(music.path),
    );

    expect(summary.music, 3);
    expect(
      Directory(
        musicDirFor(out),
      ).listSync().map((f) => f.uri.pathSegments.last).toSet(),
      {'music-41-1.png', 'music-41-2.png', 'music-doxology-1.png'},
    );
  });

  test('without music files the folder is made but stays empty', () async {
    final out = '${dir.path}/content.db';

    final summary = await buildContentDatabase(
      loadSample(),
      outPath: out,
      builtAt: DateTime.utc(2026, 10, 17),
      source: 'test',
    );

    expect(summary.music, 0);
    expect(Directory(musicDirFor(out)).listSync(), isEmpty);
  });

  test('a missing music file stops the build', () async {
    await expectLater(
      buildContentDatabase(
        loadSample(),
        outPath: '${dir.path}/content.db',
        builtAt: DateTime.utc(2026, 10, 17),
        source: 'test',
        musicFiles: DirectoryMusicFiles('${dir.path}/empty'),
      ),
      throwsA(isA<MusicFileException>()),
    );
  });

  group('notation', () {
    const score =
        '<score-partwise><part id="P1"><measure number="1">'
        '<attributes><staves>2</staves></attributes>'
        '<note><voice>1</voice><staff>1</staff>'
        '<lyric number="1"><text>A</text></lyric>'
        '<lyric number="2"><text>B</text></lyric></note>'
        '</measure></part></score-partwise>';

    DirectoryMusicFiles bucket(Map<String, String> files) {
      final folder = Directory('${dir.path}/bucket');
      for (final (path, w, h) in [
        ('hymns/041-1.png', 1200, 900),
        ('hymns/041-2.png', 1200, 500),
        ('service-music/doxology-1.png', 1200, 700),
      ]) {
        File('${folder.path}/$path')
          ..createSync(recursive: true)
          ..writeAsBytesSync(fakePng(w, h));
      }
      files.forEach((path, text) {
        File('${folder.path}/$path')
          ..createSync(recursive: true)
          ..writeAsStringSync(text);
      });
      folder.createSync(recursive: true);
      return DirectoryMusicFiles(folder.path);
    }

    test('stores the file and its verse count for a published hymn', () async {
      final notation = await readNotationFiles(
        sampleWithNotation('hymn-1'),
        bucket({'hymn-1/notation.mxl': score}),
      );
      expect(notation['hymn-1']!.verses, 2);
      expect(utf8.decode(notation['hymn-1']!.mxl), score);
    });

    test('a hymn that is not in the book is not fetched', () async {
      final notation = await readNotationFiles(
        sampleWithNotation('hymn-gone'),
        bucket({}),
      );
      expect(notation, isEmpty);
    });

    test('a file that is not MusicXML stops the build, naming it', () async {
      expect(
        readNotationFiles(
          sampleWithNotation('hymn-1'),
          bucket({'hymn-1/notation.mxl': 'not xml'}),
        ),
        throwsA(
          isA<MusicFileException>().having(
            (e) => e.path,
            'path',
            'hymn-1/notation.mxl',
          ),
        ),
      );
    });

    test('without files there is no notation', () async {
      expect(
        await readNotationFiles(sampleWithNotation('hymn-1'), null),
        isEmpty,
      );
    });

    test('the built book carries the notation and counts it', () async {
      final out = '${dir.path}/assets/content.db';
      final summary = await buildContentDatabase(
        sampleWithNotation('hymn-1'),
        outPath: out,
        builtAt: DateTime.utc(2026, 10, 31),
        source: 'example.supabase.co',
        musicFiles: bucket({'hymn-1/notation.mxl': score}),
      );
      expect(summary.notation, 1);
    });
  });
}
