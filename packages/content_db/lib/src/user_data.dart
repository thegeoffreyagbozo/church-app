import 'database.dart';
import 'models.dart';

/// The phone-only data: reading settings and the recently opened list.
class UserData {
  UserData(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// How many entries "Recently opened" keeps.
  static const recentLimit = 10;

  final ContentDatabase _db;
  final DateTime Function() _clock;

  Future<Map<String, String>> settings() async => {
    for (final row in await _db.select(_db.settings).get()) row.key: row.value,
  };

  Future<void> saveSetting(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  /// Puts an item at the top of "Recently opened", keeping the newest [recentLimit].
  Future<void> markOpened(ItemType type, String id) {
    return _db.transaction(() async {
      await _db
          .into(_db.recentlyOpened)
          .insertOnConflictUpdate(
            RecentlyOpenedCompanion.insert(
              itemType: type.wireValue,
              itemId: id,
              openedAt: _clock().toUtc(),
            ),
          );
      await _db.customStatement(
        'DELETE FROM recently_opened WHERE rowid NOT IN '
        '(SELECT rowid FROM recently_opened ORDER BY opened_at DESC '
        'LIMIT $recentLimit)',
      );
    });
  }
}
