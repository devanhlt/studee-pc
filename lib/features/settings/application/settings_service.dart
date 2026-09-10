import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/data/mathpix/mathpix_client.dart';
import 'package:studee_pc/data/mathpix/mathpix_config.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';

/// Settings workflow: DeepSeek + Mathpix credentials and connection tests.
class SettingsService {
  SettingsService({
    required CredentialsRepository credentials,
    required DeepSeekClient deepSeek,
    required MathpixClient mathpix,
  })  : _credentials = credentials,
        _deepSeek = deepSeek,
        _mathpix = mathpix;

  final CredentialsRepository _credentials;
  final DeepSeekClient _deepSeek;
  final MathpixClient _mathpix;
  final AppLogger _log = AppLogger('SettingsService');

  Future<StoredApiCredentials> loadCredentials() => _credentials.loadAll();

  Future<bool> hasKey() async => (await loadCredentials()).hasDeepSeekApiKey;

  Future<bool> hasMathpix() async =>
      (await loadCredentials()).hasMathpixCredentials;

  /// Returns a masked preview (`sk-••••1234`) or null when unset.
  Future<String?> maskedKeyPreview() async {
    final key = (await loadCredentials()).deepSeekApiKey;
    if (key == null || key.isEmpty) return null;
    if (key.length <= 8) return '••••••••';
    final suffix = key.substring(key.length - 4);
    return '••••••••$suffix';
  }

  Future<String?> maskedMathpixAppIdPreview() async {
    final id = (await loadCredentials()).mathpixAppId;
    if (id == null || id.isEmpty) return null;
    if (id.length <= 6) return '••••••';
    return '••••${id.substring(id.length - 4)}';
  }

  Future<String?> mathpixBaseUrlPreview() async {
    final url = (await loadCredentials()).mathpixBaseUrl;
    if (url == null || url.trim().isEmpty) {
      return MathpixConfig.defaultBaseUrl;
    }
    return url.trim();
  }

  Future<Result<void>> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Nhập khóa API DeepSeek',
          code: 'api_key_empty',
        ),
      );
    }
    try {
      await _credentials.setDeepSeekApiKey(trimmed);
      _log.info('API key saved');
      return const Success(null);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        UnknownFailure(
          userMessage: 'Không lưu được khóa API.',
          code: 'save_api_key_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<void>> deleteApiKey() async {
    try {
      await _credentials.deleteDeepSeekApiKey();
      _log.info('API key deleted');
      return const Success(null);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        UnknownFailure(
          userMessage: 'Không xóa được khóa API.',
          code: 'delete_api_key_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<void>> saveMathpix({
    required String appId,
    required String appKey,
    String? baseUrl,
  }) async {
    final id = appId.trim();
    final key = appKey.trim();
    if (id.isEmpty || key.isEmpty) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Nhập Mathpix app_id và app_key',
          code: 'mathpix_credentials_empty',
        ),
      );
    }
    try {
      await _credentials.setMathpixAppId(id);
      await _credentials.setMathpixAppKey(key);
      await _credentials.setMathpixBaseUrl(baseUrl);
      _log.info('Mathpix credentials saved');
      return const Success(null);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        UnknownFailure(
          userMessage: 'Không lưu được thông tin Mathpix.',
          code: 'save_mathpix_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<void>> deleteMathpix() async {
    try {
      await _credentials.deleteMathpixCredentials();
      _log.info('Mathpix credentials deleted');
      return const Success(null);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        UnknownFailure(
          userMessage: 'Không xóa được thông tin Mathpix.',
          code: 'delete_mathpix_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// Connectivity check that must not send study content.
  Future<Result<void>> testConnection() async {
    final has = await hasKey();
    if (!has) {
      return const Failure(
        MissingApiKeyFailure(
          userMessage: 'Nhập khóa API DeepSeek',
        ),
      );
    }
    try {
      await _deepSeek.testConnection();
      _log.info('DeepSeek connection OK');
      return const Success(null);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        NetworkFailure(
          userMessage: 'Không kiểm tra được kết nối DeepSeek.',
          code: 'connection_test_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<void>> testMathpixConnection() async {
    final has = await hasMathpix();
    if (!has) {
      return const Failure(
        MissingApiKeyFailure(
          userMessage: 'Nhập Mathpix app_id và app_key',
          code: 'mathpix_credentials_missing',
        ),
      );
    }
    try {
      await _mathpix.testConnection();
      return const Success(null);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        NetworkFailure(
          userMessage: 'Không kiểm tra được kết nối Mathpix.',
          code: 'mathpix_connection_test_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }
}
