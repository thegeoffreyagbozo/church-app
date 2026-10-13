import 'dart:io';

import 'package:content_db/content_db.dart';

/// The public-domain sample content used across the tests.
ContentSnapshot loadSample() => ContentSnapshot.parse(
  File('test/fixtures/sample_content.json').readAsStringSync(),
);
