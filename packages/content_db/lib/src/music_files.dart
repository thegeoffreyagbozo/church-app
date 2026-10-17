import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// A sheet-music file could not be read or isn't an image the app can show.
class MusicFileException implements Exception {
  const MusicFileException(this.path, this.reason);
  final String path;
  final String reason;

  @override
  String toString() => 'Sheet music $path: $reason';
}

/// Where the build reads sheet-music files from, by bucket and path.
abstract interface class MusicFiles {
  Future<Uint8List> read(String bucket, String path);
}

/// A church's public storage buckets (anyone may read them; ADR 0006).
class SupabaseMusicFiles implements MusicFiles {
  SupabaseMusicFiles({required String url, http.Client? client})
    : _base = Uri.parse(url.endsWith('/') ? url : '$url/'),
      _client = client ?? http.Client();

  final Uri _base;
  final http.Client _client;

  @override
  Future<Uint8List> read(String bucket, String path) async {
    final uri = _base.resolve(
      'storage/v1/object/public/$bucket/${Uri.encodeFull(path)}',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw MusicFileException(path, 'HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  void close() => _client.close();
}

/// A local folder laid out like the bucket, for builds from a saved snapshot.
class DirectoryMusicFiles implements MusicFiles {
  const DirectoryMusicFiles(this.directory);
  final String directory;

  @override
  Future<Uint8List> read(String bucket, String path) async {
    final file = File(p.join(directory, path));
    if (!file.existsSync()) {
      throw MusicFileException(path, 'no such file in $directory');
    }
    return file.readAsBytes();
  }
}
