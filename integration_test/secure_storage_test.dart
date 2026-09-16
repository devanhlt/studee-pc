import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';
import 'package:studee_pc/data/repositories/credentials_repository_impl.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Activation code round-trips through ApplicationData', (tester) async {
    final temp = await Directory.systemTemp.createTemp('studee_creds_it_');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    final repo = CredentialsRepositoryImpl(
      paths: AppPaths(applicationSupportOverride: () => temp),
    );
    const probe = 'sk-studee-test-appdata-probe-do-not-use';

    await repo.setDeepSeekApiKey(probe);
    final read = await repo.getDeepSeekApiKey();
    expect(read, probe);

    await repo.deleteDeepSeekApiKey();
    expect(await repo.hasDeepSeekApiKey(), isFalse);
  });
}
