import 'package:uuid/uuid.dart';

/// Fixed namespace for every id the importer derives. Changing it would re-key all imported
/// rows, so re-imports would duplicate content instead of updating it.
const _namespace = 'f8626e85-222d-478d-9758-87241203974d';

/// A stable row id for [key] (UUID v5): the same key always yields the same UUID, so
/// re-importing a corrected batch updates rows instead of duplicating them.
String stableId(String key) => const Uuid().v5(_namespace, key);
