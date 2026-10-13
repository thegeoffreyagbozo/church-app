import 'dart:convert';

import 'package:content_db/content_db.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('reads every table through the public API', () async {
    final asked = <String>[];
    final client = MockClient((request) async {
      final table = request.url.pathSegments.last;
      asked.add(table);
      return http.Response(
        jsonEncode(
          table == 'hymnals'
              ? [
                  {
                    'id': 'h',
                    'name': 'Hymns',
                    'is_default': true,
                    'sort_order': 0,
                  },
                ]
              : [],
        ),
        200,
      );
    });

    final snapshot = await SupabaseContentSource(
      url: 'https://example.supabase.co',
      key: 'sb_publishable_x',
      client: client,
    ).fetch();

    expect(asked, snapshotColumns.keys);
    expect(snapshot.hymnals.single['name'], 'Hymns');
  });

  test('asks for the needed columns in a stable order', () async {
    late Uri uri;
    final client = MockClient((request) async {
      uri = request.url;
      return http.Response('[]', 200);
    });

    await SupabaseContentSource(
      url: 'https://example.supabase.co/',
      key: 'k',
      client: client,
    ).fetch();

    expect(uri.path, '/rest/v1/church');
    expect(uri.queryParameters['select'], snapshotColumns['church']);
    expect(uri.queryParameters['order'], 'id.asc');
  });

  test('sends a publishable key only as apikey', () async {
    late Map<String, String> headers;
    final client = MockClient((request) async {
      headers = request.headers;
      return http.Response('[]', 200);
    });

    await SupabaseContentSource(
      url: 'https://x.supabase.co',
      key: 'sb_publishable_x',
      client: client,
    ).fetch();

    expect(headers['apikey'], 'sb_publishable_x');
    expect(headers.containsKey('Authorization'), isFalse);
  });

  test('also sends a legacy anon key as a bearer token', () async {
    late Map<String, String> headers;
    final client = MockClient((request) async {
      headers = request.headers;
      return http.Response('[]', 200);
    });

    await SupabaseContentSource(
      url: 'https://x.supabase.co',
      key: 'eyJhbGciOi',
      client: client,
    ).fetch();

    expect(headers['Authorization'], 'Bearer eyJhbGciOi');
  });

  test('pages through long tables', () async {
    final offsets = <String>[];
    final client = MockClient((request) async {
      if (request.url.pathSegments.last != 'hymns') {
        return http.Response('[]', 200);
      }
      final offset = request.url.queryParameters['offset']!;
      offsets.add(offset);
      final page = switch (offset) {
        '0' => [
          {'id': 'a'},
          {'id': 'b'},
        ],
        '2' => [
          {'id': 'c'},
          {'id': 'd'},
        ],
        _ => [
          {'id': 'e'},
        ],
      };
      return http.Response(jsonEncode(page), 200);
    });

    final snapshot = await SupabaseContentSource(
      url: 'https://x.supabase.co',
      key: 'k',
      client: client,
      pageSize: 2,
    ).fetch();

    expect(offsets, ['0', '2', '4']);
    expect(snapshot.hymns.map((h) => h['id']), ['a', 'b', 'c', 'd', 'e']);
  });

  test('names the table when the API refuses', () async {
    final client = MockClient(
      (request) async => http.Response('{"message":"bad key"}', 401),
    );

    expect(
      SupabaseContentSource(
        url: 'https://x.supabase.co',
        key: 'k',
        client: client,
      ).fetch(),
      throwsA(
        isA<ContentFetchException>()
            .having((e) => e.table, 'table', 'hymnals')
            .having((e) => e.status, 'status', 401),
      ),
    );
  });
}
