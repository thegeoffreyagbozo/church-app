import 'package:church_app/core/platform/platform_services.dart';
import 'package:church_app/startup.dart';
import 'package:content_db/content_db.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
