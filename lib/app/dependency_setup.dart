import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/data/backend/checkout_client.dart';
import 'package:studee_pc/data/backend/backend_quota_client.dart';
import 'package:studee_pc/data/catalog_database/catalog_database.dart';
import 'package:studee_pc/data/deepseek/deepseek_client_impl.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';
import 'package:studee_pc/data/file_storage/subject_file_store.dart';
import 'package:studee_pc/data/mathpix/mathpix_client.dart';
import 'package:studee_pc/data/mathpix/mathpix_ocr_service.dart';
import 'package:studee_pc/data/repositories/credentials_repository_impl.dart';
import 'package:studee_pc/data/repositories/knowledge_retriever_impl.dart';
import 'package:studee_pc/data/repositories/subject_repository_impl.dart';
import 'package:studee_pc/data/subject_database/subject_database_manager.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/domain/repositories/knowledge_retriever.dart';
import 'package:studee_pc/domain/repositories/ocr_service.dart';
import 'package:studee_pc/domain/repositories/platform_integration.dart';
import 'package:studee_pc/domain/repositories/subject_repository.dart';
import 'package:studee_pc/features/ingestion/application/ingestion_service.dart';
import 'package:studee_pc/features/practice/application/practice_service.dart';
import 'package:studee_pc/features/settings/application/privacy_consent_store.dart';
import 'package:studee_pc/features/settings/application/quota_revision.dart';
import 'package:studee_pc/features/settings/application/settings_service.dart';
import 'package:studee_pc/features/solver/application/solve_service.dart';
import 'package:studee_pc/platform/desktop_bootstrap.dart';
import 'package:studee_pc/platform/desktop_integration_impl.dart';
import 'package:studee_pc/platform/mobile_integration_impl.dart';

/// Application paths (ApplicationData root).
final appPathsProvider = Provider<AppPaths>((ref) => AppPaths());

/// Global catalog database.
final catalogDatabaseProvider = Provider<CatalogDatabase>((ref) {
  final paths = ref.watch(appPathsProvider);
  final db = CatalogDatabase.connect(paths);
  ref.onDispose(db.close);
  return db;
});

/// Opens/closes the active subject database.
final subjectDatabaseManagerProvider =
    Provider<SubjectDatabaseManager>((ref) {
  final paths = ref.watch(appPathsProvider);
  final manager = SubjectDatabaseManager(paths: paths);
  ref.onDispose(manager.close);
  return manager;
});

final subjectFileStoreProvider = Provider<SubjectFileStore>((ref) {
  return SubjectFileStore(paths: ref.watch(appPathsProvider));
});

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepositoryImpl(
    catalog: ref.watch(catalogDatabaseProvider),
    databaseManager: ref.watch(subjectDatabaseManagerProvider),
    fileStore: ref.watch(subjectFileStoreProvider),
    paths: ref.watch(appPathsProvider),
  );
});

final credentialsRepositoryProvider = Provider<CredentialsRepository>((ref) {
  return CredentialsRepositoryImpl();
});

final checkoutClientProvider = Provider<CheckoutClient>((ref) {
  return CheckoutClient();
});

final backendQuotaClientProvider = Provider<BackendQuotaClient>((ref) {
  return BackendQuotaClient(
    credentials: ref.watch(credentialsRepositoryProvider),
    onConsumed: () {
      ref.read(quotaRevisionProvider.notifier).state++;
    },
  );
});

final deepSeekClientProvider = Provider<DeepSeekClient>((ref) {
  return DeepSeekClientImpl(
    credentials: ref.watch(credentialsRepositoryProvider),
  );
});

final knowledgeRetrieverProvider = Provider<KnowledgeRetriever>((ref) {
  return KnowledgeRetrieverImpl(
    databaseManager: ref.watch(subjectDatabaseManagerProvider),
    deepSeek: ref.watch(deepSeekClientProvider),
  );
});

final mathpixClientProvider = Provider<MathpixClient>((ref) {
  return MathpixClient(
    credentials: ref.watch(credentialsRepositoryProvider),
  );
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  // Mathpix cloud OCR. OCR_FORCE_MOCK=1 keeps a local stub for offline tests.
  final forceMock =
      Platform.environment['OCR_FORCE_MOCK']?.trim().toLowerCase() == '1' ||
          Platform.environment['OCR_FORCE_MOCK']?.trim().toLowerCase() ==
              'true';
  return MathpixOcrService(
    client: ref.watch(mathpixClientProvider),
    forceMock: forceMock,
  );
});

final platformIntegrationProvider = Provider<PlatformIntegration>((ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    final impl = MobileIntegrationImpl();
    ref.onDispose(impl.dispose);
    return impl;
  }
  final impl = DesktopIntegrationImpl();
  ref.onDispose(impl.dispose);
  return impl;
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(
    credentials: ref.watch(credentialsRepositoryProvider),
    deepSeek: ref.watch(deepSeekClientProvider),
    mathpix: ref.watch(mathpixClientProvider),
  );
});

final privacyConsentStoreProvider = Provider<PrivacyConsentStore>((ref) {
  return PrivacyConsentStore();
});

final desktopBootstrapProvider = Provider<DesktopBootstrap>((ref) {
  final bootstrap = DesktopBootstrap();
  ref.onDispose(() {
    bootstrap.stop();
  });
  return bootstrap;
});

final ingestionServiceProvider = Provider<IngestionService>((ref) {
  final service = IngestionService(
    credentials: ref.watch(credentialsRepositoryProvider),
    deepSeek: ref.watch(deepSeekClientProvider),
    ocr: ref.watch(ocrServiceProvider),
    databaseManager: ref.watch(subjectDatabaseManagerProvider),
    fileStore: ref.watch(subjectFileStoreProvider),
    paths: ref.watch(appPathsProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final solveServiceProvider = Provider<SolveService>((ref) {
  final service = SolveService(
    credentials: ref.watch(credentialsRepositoryProvider),
    deepSeek: ref.watch(deepSeekClientProvider),
    ocr: ref.watch(ocrServiceProvider),
    retriever: ref.watch(knowledgeRetrieverProvider),
    databaseManager: ref.watch(subjectDatabaseManagerProvider),
    quota: ref.watch(backendQuotaClientProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final practiceServiceProvider = Provider<PracticeService>((ref) {
  final service = PracticeService(
    credentials: ref.watch(credentialsRepositoryProvider),
    deepSeek: ref.watch(deepSeekClientProvider),
    ocr: ref.watch(ocrServiceProvider),
    databaseManager: ref.watch(subjectDatabaseManagerProvider),
    quota: ref.watch(backendQuotaClientProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
