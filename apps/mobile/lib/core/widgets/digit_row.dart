import 'package:flutter/material.dart';

import '../theme/hymnal_theme.dart';

/// The app's own row of digits above the keyboard (spec section 4): Android apps can't
/// switch on a keyboard's number row, so the app draws one, on iPhone too.
class DigitRow extends StatelessWidget {
  const DigitRow({super.key, required this.onDigit});

  final ValueChanged<String> onDigit;

  @override
  Widget build(BuildContext context) {
    final theme = HymnalTheme.of(context);
    // Taps here count as taps on the search field, so it keeps the keyboard open.
    return TextFieldTapRegion(
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        decoration: BoxDecoration(
          color: theme.palette.background,
          border: Border(top: BorderSide(color: theme.palette.rule)),
        ),
        child: Row(
          children: [
            for (final digit in '1234567890'.split(''))
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: theme.palette.surface,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      key: ValueKey('digit-$digit'),
                      canRequestFocus: false,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onDigit(digit),
                      child: Center(
                        child: Text(digit, style: theme.text.digitKey),
                      ),
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

/// Puts [text] into [controller] at the cursor, replacing any selection.
void insertAtCursor(TextEditingController controller, String text) {
  final value = controller.value;
  final selection = value.selection;
  final start = selection.isValid ? selection.start : value.text.length;
  final end = selection.isValid ? selection.end : value.text.length;
  controller.value = TextEditingValue(
    text: value.text.replaceRange(start, end, text),
    selection: TextSelection.collapsed(offset: start + text.length),
  );
}
