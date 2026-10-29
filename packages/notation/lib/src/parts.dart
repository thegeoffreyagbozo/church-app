import 'package:xml/xml.dart';

/// The four voices of a hymn: soprano and alto share the top staff, tenor and bass the
/// bottom one.
enum Part { soprano, alto, tenor, bass }

/// How strongly the voices a chorister doesn't sing are drawn.
const fadedOpacity = 0.35;

bool _hasClass(XmlElement element, String name) =>
    (element.getAttribute('class') ?? '').split(' ').contains(name);

const _shapes = {
  'use',
  'path',
  'rect',
  'ellipse',
  'polygon',
  'polyline',
  'circle',
};

bool _isShape(XmlElement element) => _shapes.contains(element.name.local);

/// Whether [shape] sits in a verse group below [layer].
bool _inVerse(XmlElement shape, XmlElement layer) {
  for (
    var node = shape.parentElement;
    node != null && node != layer;
    node = node.parentElement
  ) {
    if (_hasClass(node, 'verse')) return true;
  }
  return false;
}

Iterable<XmlElement> _groups(XmlNode node, String name) =>
    node.findAllElements('g').where((g) => _hasClass(g, name));

/// [svg] (drawn by Verovio with staff@n and layer@n attributes) with every voice but
/// [keep] faded to [fadedOpacity]. On each staff the lower-numbered voice is the upper
/// part, so MuseScore's bottom-staff numbers (5 and 6) work as well as 1 and 2. The words
/// stay in full ink, so the opacity goes on each shape outside the words, never on a
/// group above them: flutter_svg multiplies a child's opacity instead of letting it
/// override its parent's.
String fadeOtherParts(String svg, Part keep) {
  final document = XmlDocument.parse(svg);

  // Every staff's voice numbers, top voice first. A voice that rests through one system
  // may be missing from it, so they are gathered over the whole drawing.
  final voicesByStaff = <int, Set<int>>{};
  for (final staff in _groups(document, 'staff')) {
    final staffN = int.tryParse(staff.getAttribute('data-n') ?? '');
    if (staffN == null) continue;
    for (final layer in _groups(staff, 'layer')) {
      final layerN = int.tryParse(layer.getAttribute('data-n') ?? '');
      if (layerN != null) (voicesByStaff[staffN] ??= {}).add(layerN);
    }
  }
  final order = {
    for (final MapEntry(:key, :value) in voicesByStaff.entries)
      key: value.toList()..sort(),
  };

  Part? partOf(int staffN, int layerN) {
    final index = order[staffN]?.indexOf(layerN) ?? -1;
    return switch ((staffN, index)) {
      (1, 0) => Part.soprano,
      (1, 1) => Part.alto,
      (2, 0) => Part.tenor,
      (2, 1) => Part.bass,
      _ => null,
    };
  }

  for (final staff in _groups(document, 'staff')) {
    final staffN = int.tryParse(staff.getAttribute('data-n') ?? '');
    if (staffN == null) continue;
    for (final layer in _groups(staff, 'layer')) {
      final layerN = int.tryParse(layer.getAttribute('data-n') ?? '');
      if (layerN == null) continue;
      final part = partOf(staffN, layerN);
      if (part == null || part == keep) continue;
      for (final shape in layer.descendantElements.where(_isShape)) {
        if (_inVerse(shape, layer)) continue;
        shape
          ..setAttribute('fill-opacity', '$fadedOpacity')
          ..setAttribute('stroke-opacity', '$fadedOpacity');
      }
    }
  }
  return document.toXmlString();
}
