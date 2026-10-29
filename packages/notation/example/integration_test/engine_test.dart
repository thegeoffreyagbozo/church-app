import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notation/src/verovio.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('Verovio loads and reports its version', () {
    final verovio = Verovio.open(null);
    addTearDown(verovio.dispose);
    expect(verovio.version, startsWith('6.3.0'));
  });
}
