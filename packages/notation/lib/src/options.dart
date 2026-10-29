import 'dart:convert';

/// Verovio's scale in percent: 40 draws a staff about 36 logical pixels tall.
const defaultScale = 40;
const minScale = 20;
const maxScale = 120;

/// Options for one tall page as wide as [width] logical pixels at [scale], broken into
/// systems automatically, with no header or footer. Verovio's page width is in its own
/// units, which [scale] percent turns into pixels.
String verovioOptions({required double width, required int scale}) {
  final s = scale.clamp(minScale, maxScale);
  final pageWidth = (width * 100 / s).round().clamp(500, 60000);
  return jsonEncode({
    'scale': s,
    'pageWidth': pageWidth,
    'pageHeight': 60000,
    'adjustPageHeight': true,
    'breaks': 'auto',
    'header': 'none',
    'footer': 'none',
    'pageMarginLeft': 20,
    'pageMarginRight': 20,
    'pageMarginTop': 20,
    'pageMarginBottom': 20,
    'font': 'Leland',
    'svgAdditionalAttribute': ['staff@n', 'layer@n'],
  });
}
