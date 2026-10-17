import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/theme/hymnal_theme.dart';
import '../../../core/widgets/keep_screen_on.dart';
import '../../../core/widgets/round_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/hymnal_providers.dart';
import 'music_pages.dart';

/// A hymn's printed music full screen: pinch or double-tap to zoom, drag to move, turn
/// the phone for a wider view. The screen stays on.
class MusicViewerScreen extends ConsumerStatefulWidget {
  const MusicViewerScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<MusicViewerScreen> createState() => _MusicViewerScreenState();
}

class _MusicViewerScreenState extends ConsumerState<MusicViewerScreen> {
  static const _zoom = 2.5;
  final _transform = TransformationController();
  Offset _tap = Offset.zero;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Zooms in around the tapped point, or back out when already zoomed.
  void _toggleZoom() {
    if (_transform.value.getMaxScaleOnAxis() > 1.01) {
      _transform.value = Matrix4.identity();
      return;
    }
    final scene = _transform.toScene(_tap);
    _transform.value = Matrix4.diagonal3Values(_zoom, _zoom, 1)
      ..setTranslationRaw(-scene.dx * (_zoom - 1), -scene.dy * (_zoom - 1), 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    final hymn = ref.watch(hymnProvider(widget.id)).value;
    return Scaffold(
      backgroundColor: theme.palette.background,
      body: KeepScreenOn(
        child: Stack(
          children: [
            if (hymn != null && hymn.music.isNotEmpty)
              Positioned.fill(
                child: GestureDetector(
                  onDoubleTapDown: (details) => _tap = details.localPosition,
                  onDoubleTap: _toggleZoom,
                  child: InteractiveViewer(
                    transformationController: _transform,
                    constrained: false,
                    minScale: 1,
                    maxScale: 5,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      child: SafeArea(child: MusicPages(hymn)),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: RoundIconButton(
                    icon: LucideIcons.x,
                    label: AppLocalizations.of(context).close,
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
