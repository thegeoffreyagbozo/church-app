import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The zip of Verovio's fonts, made by `tool/fetch_verovio_data.sh`.
const verovioAsset = 'packages/notation/assets/verovio-6.3.0.zip';

/// Written last, so a folder without it is an install that was cut short.
const completeMarker = '.complete';

/// Unpacks Verovio's fonts into app storage once (a folder per Verovio version) and
/// returns that folder. [into] replaces the app support folder in tests.
Future<String> installResources(AssetBundle bundle, {Directory? into}) async {
  final base = into ?? await getApplicationSupportDirectory();
  final folder = Directory(p.join(base.path, 'verovio-6.3.0'));
  if (File(p.join(folder.path, completeMarker)).existsSync()) {
    return folder.path;
  }

  final data = await bundle.load(verovioAsset);
  final zip = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final path = folder.path;
  // About 1,900 small files: written on a background isolate so the screen keeps moving.
  await Isolate.run(() => _unpack(zip, path));
  return folder.path;
}

void _unpack(Uint8List zip, String path) {
  final folder = Directory(path);
  if (folder.existsSync()) folder.deleteSync(recursive: true);
  folder.createSync(recursive: true);
  for (final entry in ZipDecoder().decodeBytes(zip)) {
    if (!entry.isFile) continue;
    final file = File(p.join(path, entry.name));
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(entry.readBytes()!);
  }
  File(p.join(path, completeMarker)).writeAsStringSync('');
}
