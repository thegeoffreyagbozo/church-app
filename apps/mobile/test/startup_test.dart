import 'dart:async';

import 'package:church_app/core/platform/platform_services.dart';
import 'package:church_app/features/home/presentation/home_screen.dart';
import 'package:church_app/startup.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'helpers/test_app.dart';

void main() {
  late ContentDatabase db;

  setUp(() async => db = await sampleDatabase());
  tearDown(() => db.close());

  testWidgets('a full phone gets a message and Retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      StartupApp(
        open: () async {
          if (attempts++ == 0) throw const NotEnoughSpaceException();
          return db;
        },
        overrides: [
          solidSurfacesProvider.overrideWith((ref) => false),
          appVersionProvider.overrideWith((ref) => '1.0.0 (1)'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Not enough space to set up the hymn book (needs about 3 MB).'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Grace Chapel'), findsOneWidget);
  });

  testWidgets('other failures get a general message', (tester) async {
    await tester.pumpWidget(
      StartupApp(open: () async => throw StateError('broken')),
    );
    await tester.pumpAndSettle();

    expect(find.text('The hymn book could not be opened.'), findsOneWidget);
  });

  testWidgets('lets the first frame through once the book is open', (
    tester,
  ) async {
    final opening = Completer<ContentDatabase>();
    var released = 0;
    await tester.pumpWidget(
      StartupApp(
        open: () => opening.future,
        onReady: () => released++,
        overrides: [
          solidSurfacesProvider.overrideWith((ref) => false),
          appVersionProvider.overrideWith((ref) => '1.0.0 (1)'),
        ],
      ),
    );
    await tester.pump();
    expect(released, 0, reason: 'the splash stays while the book opens');

    opening.complete(db);
    await tester.pumpAndSettle();

    expect(released, 1);
    expect(find.text('Grace Chapel'), findsOneWidget);
  });

  testWidgets('lets the first frame through once when opening fails', (
    tester,
  ) async {
    var attempts = 0;
    var released = 0;
    await tester.pumpWidget(
      StartupApp(
        open: () async {
          if (attempts++ == 0) throw const NotEnoughSpaceException();
          return db;
        },
        onReady: () => released++,
        overrides: [
          solidSurfacesProvider.overrideWith((ref) => false),
          appVersionProvider.overrideWith((ref) => '1.0.0 (1)'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(released, 1, reason: 'the message replaces the splash');

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(released, 1, reason: 'a retry has no splash to release');
  });

  testWidgets('shows the logo it loads at startup on Home', (tester) async {
    final logo = MemoryImage(img.encodePng(img.Image(width: 4, height: 4)));
    await tester.pumpWidget(
      StartupApp(
        open: () async => db,
        loadLogo: () async => logo,
        overrides: [
          solidSurfacesProvider.overrideWith((ref) => false),
          appVersionProvider.overrideWith((ref) => '1.0.0 (1)'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final image = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(Image),
    );
    expect(tester.widget<Image>(image).image, logo);
  });
}
