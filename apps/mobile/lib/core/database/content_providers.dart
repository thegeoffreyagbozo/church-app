import 'package:content_db/content_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone's hymn book. Startup opens it and overrides this provider (see
/// startup.dart); tests override it with an in-memory database.
final contentDatabaseProvider = Provider<ContentDatabase>(
  (ref) => throw StateError('The hymn book is not open yet.'),
);

final catalogProvider = Provider<ContentCatalog>(
  (ref) => ContentCatalog(ref.watch(contentDatabaseProvider)),
);

final userDataProvider = Provider<UserData>(
  (ref) => UserData(ref.watch(contentDatabaseProvider)),
);

/// The book's sections, in book order.
final sectionsProvider = FutureProvider<List<Section>>(
  (ref) => ref.watch(catalogProvider).sections(),
);

/// The church profile from the hymn book (name and contacts).
final churchProvider = FutureProvider<ChurchProfile?>(
  (ref) => ref.watch(catalogProvider).church(),
);

/// "Recently opened"; invalidated whenever an item is opened.
final recentProvider = FutureProvider<List<RecentItem>>(
  (ref) => ref.watch(catalogProvider).recentlyOpened(),
);

/// Records an opened item and refreshes "Recently opened".
final markOpenedProvider =
    Provider<Future<void> Function(ItemType type, String id)>(
      (ref) => (type, id) async {
        await ref.read(userDataProvider).markOpened(type, id);
        ref.invalidate(recentProvider);
      },
    );
