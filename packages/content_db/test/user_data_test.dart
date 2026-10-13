import 'package:content_db/content_db.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late ContentDatabase db;

  setUp(() => db = ContentDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('saves and reads settings', () async {
    final user = UserData(db);

    await user.saveSetting('text_scale', '1.4');
    await user.saveSetting('text_scale', '1.6');
    await user.saveSetting('theme', 'night');

    expect(await user.settings(), {'text_scale': '1.6', 'theme': 'night'});
  });

  test('opening an item again moves it to the top', () async {
    var minute = 0;
    final user = UserData(
      db,
      clock: () => DateTime.utc(2026, 1, 1, 9, minute++),
    );
    await user.markOpened(ItemType.hymn, 'a');
    await user.markOpened(ItemType.hymn, 'b');
    await user.markOpened(ItemType.hymn, 'a');

    final rows = await (db.select(db.recentlyOpened)).get();
    rows.sort((x, y) => y.openedAt.compareTo(x.openedAt));
    expect(rows.map((r) => r.itemId), ['a', 'b']);
  });

  test('keeps only the newest ten', () async {
    var minute = 0;
    final user = UserData(
      db,
      clock: () => DateTime.utc(2026, 1, 1, 9, minute++),
    );
    for (var i = 0; i < 12; i++) {
      await user.markOpened(ItemType.hymn, 'h$i');
    }

    final ids = (await db.select(db.recentlyOpened).get()).map((r) => r.itemId);
    expect(ids, hasLength(UserData.recentLimit));
    expect(ids, isNot(contains('h0')));
    expect(ids, isNot(contains('h1')));
  });
}
