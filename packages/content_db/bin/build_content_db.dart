import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:content_db/content_db.dart';

/// Builds the hymn book database the app bundles (spec section 6.2).
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'config',
      help:
          'App settings file holding SUPABASE_URL and SUPABASE_ANON_KEY, '
          'such as config/dev.json.',
    )
    ..addOption('url', help: 'Supabase project URL (instead of --config).')
    ..addOption('key', help: 'Publishable key (instead of --config).')
    ..addOption(
      'from-json',
      help: 'Build from a saved snapshot instead of Supabase.',
    )
    ..addOption('save-json', help: 'Also save the downloaded snapshot here.')
    ..addOption(
      'out',
      help:
          'Database file to write, such as '
          'apps/mobile/assets/content/content.db.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    _usage(parser, e.message);
  }
  if (args.flag('help')) _usage(parser, null, code: 0);
  final out = args.option('out');
  if (out == null) {
    _usage(parser, 'Say where to write the database with --out.');
  }

  final ContentSnapshot snapshot;
  final String source;
  final fromJson = args.option('from-json');
  if (fromJson != null) {
    final file = File(fromJson);
    if (!file.existsSync()) _fail(66, 'No such file: $fromJson');
    snapshot = ContentSnapshot.parse(file.readAsStringSync());
    source = 'file:${file.uri.pathSegments.last}';
  } else {
    var url = args.option('url');
    var key = args.option('key');
    final config = args.option('config');
    if (config != null) {
      final file = File(config);
      if (!file.existsSync()) _fail(66, 'No such file: $config');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      url ??= json['SUPABASE_URL'] as String?;
      key ??= json['SUPABASE_ANON_KEY'] as String?;
    }
    if (url == null || key == null) {
      _usage(parser, 'Give --from-json, --config, or both --url and --key.');
    }
    final supabase = SupabaseContentSource(url: url, key: key);
    try {
      snapshot = await supabase.fetch();
    } on ContentFetchException catch (e) {
      _fail(69, '$e');
    } on SocketException catch (e) {
      _fail(69, 'Could not reach $url: ${e.message}');
    } finally {
      supabase.close();
    }
    source = Uri.parse(url).host;
    final save = args.option('save-json');
    if (save != null) {
      File(save).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
      );
    }
  }

  final summary = await buildContentDatabase(
    snapshot,
    outPath: out,
    builtAt: DateTime.now().toUtc(),
    source: source,
  );
  stdout.writeln(
    'Wrote $out: ${summary.sections} sections, ${summary.hymns} hymns '
    '(${summary.verses} verses and choruses), ${summary.readings} readings '
    '(${summary.parts} parts).',
  );
  if (summary.skipped > 0) {
    stdout.writeln(
      'Left out ${summary.skipped} rows whose section, hymn or reading '
      "isn't published.",
    );
  }
}

Never _usage(ArgParser parser, String? problem, {int code = 64}) {
  if (problem != null) stderr.writeln(problem);
  (code == 0 ? stdout : stderr)
    ..writeln('Usage: dart run content_db:build_content_db [options]')
    ..writeln(parser.usage);
  exit(code);
}

Never _fail(int code, String message) {
  stderr.writeln(message);
  exit(code);
}
