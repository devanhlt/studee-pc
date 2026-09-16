import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';
import 'package:studee_pc/data/repositories/credentials_repository_impl.dart';

void main() {
  late Directory tempRoot;
  late AppPaths paths;
  late CredentialsRepositoryImpl repo;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('studee_creds_');
    paths = AppPaths(applicationSupportOverride: () => tempRoot);
    repo = CredentialsRepositoryImpl(paths: paths);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('activation code round-trips through ApplicationData file', () async {
    const code = 'ACT-TEST-ROUNDTRIP-12345';

    await repo.setActivationCode(code);
    expect(await repo.getActivationCode(), code);
    expect(await repo.hasActivationCode(), isTrue);

    final filePath = await paths.credentialsFilePath();
    final file = File(filePath);
    expect(await file.exists(), isTrue);

    final raw = await file.readAsBytes();
    expect(raw.take(4).toList(), [0x53, 0x54, 0x55, 0x31]);
    expect(utf8.decode(raw, allowMalformed: true), isNot(contains(code)));

    final reloaded = CredentialsRepositoryImpl(paths: paths);
    expect(await reloaded.getActivationCode(), code);

    await reloaded.deleteActivationCode();
    expect(await reloaded.hasActivationCode(), isFalse);
    expect(await file.exists(), isFalse);
  });
}
