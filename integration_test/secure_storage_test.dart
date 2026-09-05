import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studee_pc/data/repositories/credentials_repository_impl.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DeepSeek API key round-trips through Keychain', (tester) async {
    final repo = CredentialsRepositoryImpl();
    const probe = 'sk-studee-test-keychain-probe-do-not-use';

    await repo.setDeepSeekApiKey(probe);
    final read = await repo.getDeepSeekApiKey();
    expect(read, probe);

    await repo.deleteDeepSeekApiKey();
    expect(await repo.hasDeepSeekApiKey(), isFalse);
  });
}
