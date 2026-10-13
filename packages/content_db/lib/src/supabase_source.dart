import 'dart:convert';

import 'package:http/http.dart' as http;

import 'snapshot.dart';

/// The Supabase API refused a request.
class ContentFetchException implements Exception {
  const ContentFetchException(this.table, this.status, this.body);

  final String table;
  final int status;
  final String body;

  @override
  String toString() => 'Reading $table failed with HTTP $status: $body';
}

/// Reads a church's published content through its public API, as anyone may: row
/// level security returns only published, non-deleted rows (ADR 0006: public key only).
class SupabaseContentSource {
  SupabaseContentSource({
    required String url,
    required this.key,
    http.Client? client,
    this.pageSize = 1000,
  }) : _base = Uri.parse(url.endsWith('/') ? url : '$url/'),
       _client = client ?? http.Client();

  final Uri _base;

  /// The publishable (or legacy anon) key.
  final String key;

  /// Rows per request; the API returns at most 1000 (`max_rows`).
  final int pageSize;
  final http.Client _client;

  Future<ContentSnapshot> fetch() async => ContentSnapshot.fromJson({
    for (final MapEntry(key: table, value: columns) in snapshotColumns.entries)
      table: await _all(table, columns),
  });

  Future<List<ApiRow>> _all(String table, String columns) async {
    final rows = <ApiRow>[];
    for (var offset = 0; ; offset += pageSize) {
      final uri = _base
          .resolve('rest/v1/$table')
          .replace(
            queryParameters: {
              'select': columns,
              'order': 'id.asc',
              'limit': '$pageSize',
              'offset': '$offset',
            },
          );
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode != 200) {
        throw ContentFetchException(table, response.statusCode, response.body);
      }
      final page = (jsonDecode(response.body) as List<Object?>).cast<ApiRow>();
      rows.addAll(page);
      if (page.length < pageSize) return rows;
    }
  }

  // Legacy anon keys are JWTs and also go in Authorization; publishable keys
  // (sb_publishable_...) must not.
  Map<String, String> get _headers => {
    'apikey': key,
    if (key.startsWith('eyJ')) 'Authorization': 'Bearer $key',
    'Accept': 'application/json',
  };

  void close() => _client.close();
}
