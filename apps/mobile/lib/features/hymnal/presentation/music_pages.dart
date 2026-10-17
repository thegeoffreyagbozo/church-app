import 'package:content_db/content_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/hymnal_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/hymnal_providers.dart';

/// A colour matrix that draws a black-and-white scan as [ink] on a clear page: black
/// becomes [ink], white becomes transparent, greys in between. So Paper shows dark ink
/// on paper and Night light ink on dark. Alpha is the pixel's own alpha less its
/// brightness, so clear pixels stay clear: a filter that made them opaque would be
/// painted over everything around the image.
List<double> inkMatrix(Color ink) => [
  0, 0, 0, 0, ink.r * 255, //
  0, 0, 0, 0, ink.g * 255,
  0, 0, 0, 0, ink.b * 255,
  -0.2126, -0.7152, -0.0722, 1, 0,
];

/// A hymn's printed music, piece under piece, the width of the page.
class MusicPages extends ConsumerWidget {
  const MusicPages(this.hymn, {super.key, this.onTap});

  final HymnDetail hymn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = HymnalTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final image = ref.watch(musicImageProvider);
    final filter = ColorFilter.matrix(inkMatrix(theme.palette.ink));
    return Semantics(
      button: onTap != null,
      label: l10n.musicImageLabel(hymn.title),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pixels =
                (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                    .round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final part in hymn.music)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AspectRatio(
                      aspectRatio: part.aspectRatio,
                      child: ColorFiltered(
                        colorFilter: filter,
                        child: Image(
                          image: ResizeImage(image(part.id), width: pixels),
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                          errorBuilder: (context, _, _) => Center(
                            child: Text(
                              l10n.musicMissing,
                              style: theme.text.caption,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
