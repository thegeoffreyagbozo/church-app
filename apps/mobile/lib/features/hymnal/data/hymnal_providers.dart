import 'package:content_db/content_db.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/content_providers.dart';
import '../domain/contents.dart';

final sectionProvider = FutureProvider.family<Section?, String>(
  (ref, id) => ref.watch(catalogProvider).section(id),
);

final sectionHymnsProvider = FutureProvider.family<List<HymnListItem>, String>(
  (ref, id) => ref.watch(catalogProvider).hymnsIn(id),
);

/// A section's hymns under the titles of the book's contents.
final sectionContentsProvider = FutureProvider.family<SectionContents, String>(
  (ref, id) async =>
      sectionContents(await ref.watch(sectionHymnsProvider(id).future)),
);

final hymnProvider = FutureProvider.family<HymnDetail?, String>(
  (ref, id) => ref.watch(catalogProvider).hymn(id),
);

/// The image of one piece of a hymn's printed music, bundled beside the database.
/// Tests swap in images made in memory.
final musicImageProvider = Provider<ImageProvider Function(String id)>(
  (ref) =>
      (id) => AssetImage('assets/content/music/$id.png'),
);
