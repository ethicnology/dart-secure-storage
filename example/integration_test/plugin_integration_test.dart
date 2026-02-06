import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:secure_storage/secure_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store/fetch/trash round-trip', (WidgetTester tester) async {
    final plugin = createSecureStorage();
    const key = 'plugin_test_key';
    const value = 'hello plugin';
    await plugin.storeString(key, value);
    final fetched = await plugin.fetchString(key);
    expect(fetched, value);
    await plugin.trash(key);
    expect(await plugin.fetchString(key), isNull);
  });
}
