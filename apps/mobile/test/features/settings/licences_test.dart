import 'package:church_app/main.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Licences page lists Verovio and the notation fonts', () async {
    app.registerLicences();
    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
    }
    expect(
      packages,
      containsAll(['Verovio', 'Bravura', 'Leipzig', 'Leland', 'Tinos']),
    );
  });
}
