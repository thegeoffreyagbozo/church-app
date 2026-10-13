import 'package:content_db/content_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/content_providers.dart';

final searchEngineProvider = Provider<SearchEngine>(
  (ref) => SearchEngine(
    ref.watch(contentDatabaseProvider),
    ref.watch(catalogProvider),
  ),
);

/// What is typed in the search bar.
final searchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void change(String query) => state = query;
}

/// Results for the current query, recomputed on every key press. While new results
/// load, `.value` still holds the previous ones, so the list never flickers.
final searchResultsProvider = FutureProvider<SearchResults>(
  (ref) =>
      ref.watch(searchEngineProvider).search(ref.watch(searchQueryProvider)),
);
