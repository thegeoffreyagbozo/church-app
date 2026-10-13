import 'package:content_db/content_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/content_providers.dart';

final sectionProvider = FutureProvider.family<Section?, String>(
  (ref, id) => ref.watch(catalogProvider).section(id),
);

final sectionHymnsProvider = FutureProvider.family<List<HymnListItem>, String>(
  (ref, id) => ref.watch(catalogProvider).hymnsIn(id),
);

final hymnProvider = FutureProvider.family<HymnDetail?, String>(
  (ref, id) => ref.watch(catalogProvider).hymn(id),
);
