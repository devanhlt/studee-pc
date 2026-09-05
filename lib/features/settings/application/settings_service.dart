import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';

/// Settings workflow: API key save / test / delete and [hasKey] gate.
class SettingsService {
  SettingsService({
    required CredentialsRepository credentials,
    required DeepSeekClient deepSeek,
  })  : _credentials = credentials,
        _deepSeek = deepSeek;

  final CredentialsRepository _credentials;
  final DeepSeekClient _deepSeek;
  final AppLogger _log = AppLogger('SettingsService');

  Future<bool> hasKey() => _credentials.hasDeepSeekApiKey();

  /// Returns a masked preview (`sk-••••1234`) or null when unset.
  Future<String?> maskedKeyPreview() async {
    final key = await _credentials.getDeepSeekApiKey();
    if (key == null || key.isEmpty) return null;
    if (key.length <= 8) return '••••••••';
    final suffix = key.substring(key.length - 4);
    return '••••••••$suffix';
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
}
