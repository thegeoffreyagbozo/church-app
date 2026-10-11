import 'package:content_import/content_import.dart';
import 'package:test/test.dart';

void main() {
  // Expected values computed independently with Python's uuid.uuid5 and the
  // importer's namespace (f8626e85-222d-478d-9758-87241203974d).
  test('derives the same UUID v5 as an independent implementation', () {
    expect(
      stableId('hymn/en/Hymns/267'),
      'adc30a52-ba79-5b60-aea7-82989017a58b',
    );
    expect(stableId('reading/en/60'), '1418878a-1bef-52b8-aab8-71e5a51c4e8c');
  });

  test('different keys give different ids', () {
    expect(
      stableId('hymn/en/Hymns/268'),
      'd20b71b5-e26a-5b17-a3dc-d826ed3b9932',
    );
  });
}
