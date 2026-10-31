import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/page_width.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/domain/reading_settings.dart';
import '../../settings/presentation/settings_controller.dart';
import '../data/notation_drawer.dart';
import 'music_pages.dart';

/// A hymn's drawn notation in the Music view: verse chips, the part picker, and the
/// drawing in the theme's ink (ADR 0012). If drawing fails, the scanned music shows.
class NotationView extends ConsumerStatefulWidget {
  const NotationView(this.hymn, {super.key});

  final HymnDetail hymn;

  @override
  ConsumerState<NotationView> createState() => _NotationViewState();
}

class _NotationViewState extends ConsumerState<NotationView> {
  var _verse = 1;

  /// The last drawing shown, kept on screen while the next one is made.
  List<String>? _last;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = HymnalTheme.of(context);
    final hymn = widget.hymn;
    final width = itemContentWidth(context);
    final part = ref.watch(readingSettingsProvider.select((s) => s.hymnPart));
    final scale = notationScale(
      ref.watch(readingSettingsProvider.select((s) => s.textScale)),
    );
    final drawing = ref.watch(
      notationDrawingProvider((
        hymnId: hymn.id,
        width: width,
        verse: _verse,
        part: part,
        scale: scale,
      )),
    );
    if (drawing case AsyncData(:final value)) _last = value;
    if (drawing case AsyncError(:final error) when _last == null) {
      debugPrint('Notation of ${hymn.id} could not be drawn: $error');
      return hymn.music.isEmpty
          ? const SizedBox.shrink()
          : MusicPages(hymn, onTap: () => context.push(hymnMusicPath(hymn.id)));
    }
    final pages = _last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hymn.notationVerses > 1)
          Wrap(
            spacing: 8,
            children: [
              for (var v = 1; v <= hymn.notationVerses; v++)
                Semantics(
                  label: l10n.verseNumber(v),
                  excludeSemantics: true,
                  child: ChoiceChip(
                    label: Text('$v'),
                    selected: _verse == v,
                    onSelected: (_) => setState(() => _verse = v),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 8),
        SegmentedButton<HymnPart>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: HymnPart.all,
              label: const Text('All'),
              tooltip: l10n.partAll,
            ),
            ButtonSegment(
              value: HymnPart.soprano,
              label: const Text('S'),
              tooltip: l10n.partSoprano,
            ),
            ButtonSegment(
              value: HymnPart.alto,
              label: const Text('A'),
              tooltip: l10n.partAlto,
            ),
            ButtonSegment(
              value: HymnPart.tenor,
              label: const Text('T'),
              tooltip: l10n.partTenor,
            ),
            ButtonSegment(
              value: HymnPart.bass,
              label: const Text('B'),
              tooltip: l10n.partBass,
            ),
          ],
          selected: {part},
          onSelectionChanged: (s) =>
              ref.read(readingSettingsProvider.notifier).setHymnPart(s.single),
        ),
        const SizedBox(height: 12),
        if (pages == null)
          const SizedBox(height: 240)
        else
          Semantics(
            label: l10n.notationLabel(hymn.title, _verse),
            image: true,
            excludeSemantics: true,
            child: Column(
              children: [
                for (final page in pages)
                  SvgPicture.string(
                    page,
                    width: width,
                    colorFilter: ColorFilter.mode(
                      theme.palette.ink,
                      BlendMode.srcIn,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Starts drawing every verse of [hymn]'s notation as soon as its page opens (verse 1
/// first), so the Music view and its verse chips show without waiting.
class NotationPrefetch extends ConsumerStatefulWidget {
  const NotationPrefetch({super.key, required this.hymn, required this.child});

  final HymnDetail hymn;
  final Widget child;

  @override
  ConsumerState<NotationPrefetch> createState() => _NotationPrefetchState();
}

class _NotationPrefetchState extends ConsumerState<NotationPrefetch> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefetch());
  }

  Future<void> _prefetch() async {
    if (!mounted) return;
    final hymn = widget.hymn;
    final settings = ref.read(readingSettingsProvider);
    final width = itemContentWidth(context);
    final drawer = ref.read(notationDrawerProvider);
    final String? musicXml;
    try {
      musicXml = await ref.read(hymnNotationProvider(hymn.id).future);
    } on Object {
      return; // the Music view reports it and falls back
    }
    if (musicXml == null) return;
    for (var v = 1; v <= hymn.notationVerses; v++) {
      drawer
          .draw(
            musicXml,
            width: width,
            verse: v,
            part: settings.hymnPart,
            scale: notationScale(settings.textScale),
          )
          .ignore();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
