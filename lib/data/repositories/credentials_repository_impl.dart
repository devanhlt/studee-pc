import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';

/// Stores the DeepSeek API key in the OS credential store only.
///
/// Never writes secrets to SQLite, shared preferences, or logs.
class CredentialsRepositoryImpl implements CredentialsRepository {
  CredentialsRepositoryImpl({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
              // Legacy keychain avoids Data Protection Keychain entitlement
              // errors (-34018) for sandboxed / personal macOS builds.
              mOptions: MacOsOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
                useDataProtectionKeyChain: false,
              ),
              wOptions: WindowsOptions(useBackwardCompatibility: false),
            );

  static const String _deepSeekKey = 'deepseek_api_key';

  final FlutterSecureStorage _storage;
  final AppLogger _log = AppLogger('CredentialsRepository');

  @override
  Future<String?> getDeepSeekApiKey() async {
    try {
      final value = await _storage.read(key: _deepSeekKey);
      if (value == null) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    } on Object catch (e) {
      _log.severe('Failed to read API key from secure storage', e);
      throw const UnknownFailure(
        userMessage: 'Không đọc được khóa API từ kho bảo mật hệ thống.',
        code: 'secure_storage_read_failed',
      );
    }
  }

  @override
  Future<void> setDeepSeekApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    try {
      if (trimmed.isEmpty) {
        await deleteDeepSeekApiKey();
        return;
      }
      await _storage.write(key: _deepSeekKey, value: trimmed);
      _log.info('DeepSeek API key updated in secure storage');
    } on Object catch (e) {
      _log.severe('Failed to write API key to secure storage', e);
      final detail = e.toString();
      final missingEntitlement = detail.contains('-34018') ||
          detail.contains('entitlement') ||
          detail.contains('MissingEntitlement');
      throw UnknownFailure(
        userMessage: missingEntitlement
            ? 'Không lưu được khóa API: macOS Keychain thiếu quyền. '
                'Hãy thoát app và chạy lại (flutter run) sau khi cập nhật entitlements.'
            : 'Không lưu được khóa API vào kho bảo mật hệ thống.',
        code: 'secure_storage_write_failed',
        details: e.runtimeType.toString(),
      );
    }
  }

  @override
  Future<void> deleteDeepSeekApiKey() async {
    try {
      await _storage.delete(key: _deepSeekKey);
      _log.info('DeepSeek API key deleted from secure storage');
    } on Object catch (e) {
      _log.severe('Failed to delete API key from secure storage', e);
      throw const UnknownFailure(
        userMessage: 'Không xóa được khóa API khỏi kho bảo mật hệ thống.',
        code: 'secure_storage_delete_failed',
      );
    }
  }

  @override
  Future<bool> hasDeepSeekApiKey() async {
    final key = await getDeepSeekApiKey();
    return key != null && key.isNotEmpty;
  }
}
