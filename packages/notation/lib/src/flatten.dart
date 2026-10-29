import 'package:xml/xml.dart';

/// The bundled font with Times' letter widths, which Verovio spaces the words by.
const tinosFamily = 'packages/notation/Tinos';

bool _isLabel(XmlElement g) =>
    (g.getAttribute('class') ?? '').split(' ').contains('label');

/// [value] to two decimals, without trailing zeros.
String _round(double value) =>
    double.parse(value.toStringAsFixed(2)).toString();

double? _pixels(String? length) =>
    double.tryParse((length ?? '').replaceAll('px', ''));

/// [svg] from Verovio reshaped for `flutter_svg`, which draws nothing inside a nested
/// `<svg>`, ignores `<style>`, and doesn't scale a font size set on a nested `<tspan>`:
/// the inner, viewBox-scaled `<svg>` becomes a group with the same scale, the
/// stylesheet's one rule that matters (lines drawn in the current colour) moves onto that
/// group, and each text carries its own font size (already scaled) and plain words. The part name Verovio
/// prints before the first line is dropped.
String flattenForFlutter(String svg) {
  final document = XmlDocument.parse(svg);
  final root = document.rootElement;
  final inner = root.childElements
      .where((e) => e.name.local == 'svg')
      .firstOrNull;
  if (inner == null) return document.toXmlString();

  final viewBox = (inner.getAttribute('viewBox') ?? '').split(
    RegExp(r'[\s,]+'),
  );
  final width = _pixels(root.getAttribute('width'));
  final height = _pixels(root.getAttribute('height'));
  final boxWidth = viewBox.length == 4 ? double.tryParse(viewBox[2]) : null;
  final boxHeight = viewBox.length == 4 ? double.tryParse(viewBox[3]) : null;
  if (width == null ||
      height == null ||
      boxWidth == null ||
      boxHeight == null) {
    return document.toXmlString();
  }

  final group = XmlElement(
    XmlName('g'),
    [
      for (final attribute in inner.attributes)
        if (attribute.name.local != 'viewBox' &&
            attribute.name.local != 'font-family')
          attribute.copy(),
      XmlAttribute(XmlName('font-family'), tinosFamily),
      XmlAttribute(
        XmlName('transform'),
        'scale(${width / boxWidth} ${height / boxHeight})',
      ),
      XmlAttribute(XmlName('stroke'), 'currentColor'),
    ],
    [for (final child in inner.children.toList()) child..remove()],
  );
  inner.replace(group);
  for (final label in group.findAllElements('g').where(_isLabel).toList()) {
    label.remove();
  }
  for (final text in group.findAllElements('text')) {
    final sized = text
        .findAllElements('tspan')
        .where((t) => t.getAttribute('font-size') != null);
    final size = _pixels(sized.lastOrNull?.getAttribute('font-size'));
    final words = text.innerText.trim();
    // flutter_svg moves text with the group's scale but draws its glyphs at the font size
    // as given, so the size is scaled here instead.
    if (size != null) {
      text.setAttribute('font-size', '${_round(size * height / boxHeight)}px');
    }
    // The group's line colour would outline the glyphs too, unscaled, making them bold.
    text.setAttribute('stroke', 'none');
    text.children
      ..clear()
      ..add(XmlText(words));
  }
  for (final style
      in root.childElements.where((e) => e.name.local == 'style').toList()) {
    style.remove();
  }
  return document.toXmlString();
}
