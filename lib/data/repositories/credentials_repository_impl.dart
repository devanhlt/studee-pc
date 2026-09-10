import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';

/// Stores API keys in the OS credential store only.
///
/// Uses a single [FlutterSecureStorage.readAll] when possible and keeps an
/// in-memory cache until the next write/delete.
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
  static const String _mathpixAppIdKey = 'mathpix_app_id';
  static const String _mathpixAppKeyKey = 'mathpix_app_key';
  static const String _mathpixBaseUrlKey = 'mathpix_base_url';

  final FlutterSecureStorage _storage;
  final AppLogger _log = AppLogger('CredentialsRepository');

  StoredApiCredentials? _cache;
  Future<StoredApiCredentials>? _inFlight;

  void _invalidateCache() {
    _cache = null;
    _inFlight = null;
  }

  static String? _trimOrNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<StoredApiCredentials> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final pending = _inFlight;
    if (pending != null) return pending;

    final future = _readAllFromStorage();
    _inFlight = future;
    try {
      final snapshot = await future;
      _cache = snapshot;
      return snapshot;
    } finally {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    }
  }

  Future<StoredApiCredentials> _readAllFromStorage() async {
    try {
      final all = await _storage.readAll();
      return StoredApiCredentials(
        deepSeekApiKey: _trimOrNull(all[_deepSeekKey]),
        mathpixAppId: _trimOrNull(all[_mathpixAppIdKey]),
        mathpixAppKey: _trimOrNull(all[_mathpixAppKeyKey]),
        mathpixBaseUrl: _trimOrNull(all[_mathpixBaseUrlKey]),
      );
    } on Object catch (e) {
      // macOS Keychain often fails on readAll() while per-key read() works.
      _log.warning(
        'readAll failed (${e.runtimeType}); falling back to per-key reads',
      );
      return _readKnownKeysIndividually();
    }
  }

  /// Per-key reads when [readAll] is unavailable.
  ///
  /// Reads are **sequential** so macOS Keychain typically prompts once; the
  /// first unlock covers following reads in the same session.
  Future<StoredApiCredentials> _readKnownKeysIndividually() async {
    try {
      final deepSeek = await _storage.read(key: _deepSeekKey);
      final mathpixId = await _storage.read(key: _mathpixAppIdKey);
      final mathpixKey = await _storage.read(key: _mathpixAppKeyKey);
      final mathpixUrl = await _storage.read(key: _mathpixBaseUrlKey);
      return StoredApiCredentials(
        deepSeekApiKey: _trimOrNull(deepSeek),
        mathpixAppId: _trimOrNull(mathpixId),
        mathpixAppKey: _trimOrNull(mathpixKey),
        mathpixBaseUrl: _trimOrNull(mathpixUrl),
      );
    } on Object catch (e) {
      _log.severe('Failed to read credentials from secure storage', e);
      throw UnknownFailure(
        userMessage: 'Không đọc được khóa API từ kho bảo mật hệ thống.',
        code: 'secure_storage_read_failed',
        details: e.runtimeType.toString(),
      );
    }
  }

  Future<void> _write(String key, String value, {required String label}) async {
    final trimmed = value.trim();
    try {
      if (trimmed.isEmpty) {
        await _storage.delete(key: key);
        _invalidateCache();
        return;
      }
      await _storage.write(key: key, value: trimmed);
      _invalidateCache();
      _log.info('$label updated in secure storage');
    } on Object catch (e) {
      _log.severe('Failed to write $key to secure storage', e);
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
  Future<String?> getDeepSeekApiKey() async =>
      (await loadAll()).deepSeekApiKey;

  @override
  Future<void> setDeepSeekApiKey(String apiKey) =>
      _write(_deepSeekKey, apiKey, label: 'DeepSeek API key');

  @override
  Future<void> deleteDeepSeekApiKey() async {
    try {
      await _storage.delete(key: _deepSeekKey);
      _invalidateCache();
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
  Future<bool> hasDeepSeekApiKey() async =>
      (await loadAll()).hasDeepSeekApiKey;

  @override
  Future<String?> getMathpixAppId() async => (await loadAll()).mathpixAppId;

  @override
  Future<String?> getMathpixAppKey() async => (await loadAll()).mathpixAppKey;

  @override
  Future<String?> getMathpixBaseUrl() async =>
      (await loadAll()).mathpixBaseUrl;

  @override
  Future<void> setMathpixAppId(String appId) =>
      _write(_mathpixAppIdKey, appId, label: 'Mathpix app_id');

  @override
  Future<void> setMathpixAppKey(String appKey) =>
      _write(_mathpixAppKeyKey, appKey, label: 'Mathpix app_key');

  @override
  Future<void> setMathpixBaseUrl(String? baseUrl) async {
    final trimmed = baseUrl?.trim() ?? '';
    try {
      if (trimmed.isEmpty) {
        await _storage.delete(key: _mathpixBaseUrlKey);
      } else {
        await _storage.write(key: _mathpixBaseUrlKey, value: trimmed);
      }
      _invalidateCache();
      _log.info('Mathpix base URL updated in secure storage');
    } on Object catch (e) {
      _log.severe('Failed to write Mathpix base URL', e);
      throw const UnknownFailure(
        userMessage: 'Không lưu được URL Mathpix.',
        code: 'secure_storage_write_failed',
      );
    }
  }

  @override
  Future<void> deleteMathpixCredentials() async {
    try {
      await _storage.delete(key: _mathpixAppIdKey);
      await _storage.delete(key: _mathpixAppKeyKey);
      await _storage.delete(key: _mathpixBaseUrlKey);
      _invalidateCache();
      _log.info('Mathpix credentials deleted from secure storage');
    } on Object catch (e) {
      _log.severe('Failed to delete Mathpix credentials', e);
      throw const UnknownFailure(
        userMessage: 'Không xóa được khóa Mathpix khỏi kho bảo mật hệ thống.',
        code: 'secure_storage_delete_failed',
      );
    }
  }

  @override
  Future<bool> hasMathpixCredentials() async =>
      (await loadAll()).hasMathpixCredentials;
}
