import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/settings_controller.dart';

/// The text scale for hymn and reading text: the phone's own text size times the
/// reader's in-app size, capped at 2.5 times the 20 sp base (spec section 7).
TextScaler readingTextScaler(TextScaler phone, double multiplier) {
  const base = 20.0;
  final factor = phone.scale(base) / base * multiplier;
  return TextScaler.linear(factor.clamp(0.5, 2.5).toDouble());
}

/// Applies [readingTextScaler] to [child].
class ReadingTextScale extends ConsumerWidget {
  const ReadingTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final multiplier = ref.watch(
      readingSettingsProvider.select((s) => s.textScale),
    );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: readingTextScaler(
          MediaQuery.textScalerOf(context),
          multiplier,
        ),
      ),
      child: child,
    );
  }
}
