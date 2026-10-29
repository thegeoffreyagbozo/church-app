import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:notation/notation.dart';
import 'package:notation/testing.dart';

void main() => runApp(const ViewerApp());

/// Shows the fixture as the Music view will: verse chips, a part picker, Paper or Night,
/// and a size slider. For the owner's readability check in the go/no-go.
class ViewerApp extends StatefulWidget {
  const ViewerApp({super.key});

  @override
  State<ViewerApp> createState() => _ViewerAppState();
}

class _ViewerAppState extends State<ViewerApp> {
  final _hymn = oldHundredth();
  late final Future<NotationEngine> _engine = NotationEngine.start();
  var _verse = 1;
  Part? _part;
  var _night = false;
  var _scale = defaultScale.toDouble();

  @override
  Widget build(BuildContext context) {
    final paper = _night ? const Color(0xFF14161A) : const Color(0xFFFBF8F1);
    final ink = _night ? const Color(0xFFE8E4DA) : const Color(0xFF1C1B19);
    return MaterialApp(
      theme: ThemeData(brightness: _night ? Brightness.dark : Brightness.light),
      home: Scaffold(
        backgroundColor: paper,
        appBar: AppBar(
          title: const Text('Old Hundredth'),
          actions: [
            IconButton(
              icon: Icon(_night ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _night = !_night),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (var v = 1; v <= verseCount(_hymn); v++)
                  ChoiceChip(
                    label: Text('$v'),
                    selected: _verse == v,
                    onSelected: (_) => setState(() => _verse = v),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<Part?>(
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(value: Part.soprano, label: Text('S')),
                ButtonSegment(value: Part.alto, label: Text('A')),
                ButtonSegment(value: Part.tenor, label: Text('T')),
                ButtonSegment(value: Part.bass, label: Text('B')),
              ],
              selected: {_part},
              onSelectionChanged: (s) => setState(() => _part = s.single),
            ),
            Slider(
              min: minScale.toDouble(),
              max: maxScale.toDouble(),
              value: _scale,
              onChanged: (v) => setState(() => _scale = v),
            ),
            LayoutBuilder(
              builder: (context, constraints) => FutureBuilder<List<String>>(
                future: _engine.then(
                  (engine) => engine.render(
                    _hymn,
                    width: constraints.maxWidth,
                    verse: _verse,
                    part: _part,
                    scale: _scale.round(),
                  ),
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('${snapshot.error}');
                  final pages = snapshot.data;
                  if (pages == null) return const SizedBox(height: 200);
                  return Column(
                    children: [
                      for (final page in pages)
                        SvgPicture.string(
                          page,
                          width: constraints.maxWidth,
                          colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
