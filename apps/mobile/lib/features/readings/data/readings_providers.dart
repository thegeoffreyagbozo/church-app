import 'package:content_db/content_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/content_providers.dart';

final readingsProvider = FutureProvider<List<ReadingListItem>>(
  (ref) => ref.watch(catalogProvider).readings(),
);

final readingProvider = FutureProvider.family<ReadingDetail?, String>(
  (ref, id) => ref.watch(catalogProvider).reading(id),
);
