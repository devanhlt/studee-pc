import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';

/// Stores API keys in the OS credential store only.
///
/// All secrets live in **one** Keychain item ([_bundleKey]) so macOS typically
/// prompts once per unlock, then [loadAll] serves an in-memory cache.
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

  /// Single Keychain item — avoids one unlock prompt per secret.
  static const String _bundleKey = 'studee_api_credentials_v1';

  // Legacy per-key items (migrated into [_bundleKey] on first read).
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

    final future = _readFromStorage();
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

  Future<StoredApiCredentials> _readFromStorage() async {
    try {
      final raw = await _storage.read(key: _bundleKey);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return StoredApiCredentials.fromJson(decoded);
        }
        if (decoded is Map) {
          return StoredApiCredentials.fromJson(
            decoded.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      }
    } on Object catch (e) {
      _log.warning('Bundle read failed (${e.runtimeType}); trying legacy keys');
    }

    final legacy = await _readLegacyKeys();
    if (legacy.hasAny) {
      try {
        await _persistBundle(legacy);
        await _deleteLegacyKeysBestEffort();
        _log.info('Migrated legacy Keychain keys into single bundle');
      } on Object catch (e) {
        _log.warning('Legacy migration write failed (${e.runtimeType})');
      }
    }
    return legacy;
  }

  Future<StoredApiCredentials> _readLegacyKeys() async {
    try {
      final all = await _storage.readAll();
      return StoredApiCredentials(
        deepSeekApiKey: _trimOrNull(all[_deepSeekKey]),
        mathpixAppId: _trimOrNull(all[_mathpixAppIdKey]),
        mathpixAppKey: _trimOrNull(all[_mathpixAppKeyKey]),
        mathpixBaseUrl: _trimOrNull(all[_mathpixBaseUrlKey]),
      );
    } on Object catch (_) {
      // Fall through to sequential reads.
    }

    try {
      // One sequential pass — still may prompt per item on first migrate.
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

  Future<void> _persistBundle(StoredApiCredentials snapshot) async {
    try {
      await _storage.write(
        key: _bundleKey,
        value: jsonEncode(snapshot.toJson()),
      );
      _cache = snapshot;
      _inFlight = null;
    } on Object catch (e) {
      _log.severe('Failed to write credentials bundle', e);
      final detail = e.toString();
      final missingEntitlement = detail.contains('-34018') ||
          detail.contains('entitlement') ||
          detail.contains('MissingEntitlement');
      throw UnknownFailure(
        userMessage: missingEntitlement
            ? 'Không lưu được khóa API: macOS Keychain thiếu quyền. '
                'Hãy thoát app và chạy lại sau khi cập nhật entitlements.'
            : 'Không lưu được khóa API vào kho bảo mật hệ thống.',
        code: 'secure_storage_write_failed',
        details: e.runtimeType.toString(),
      );
    }
  }

  Future<void> _deleteLegacyKeysBestEffort() async {
    for (final key in [
      _deepSeekKey,
      _mathpixAppIdKey,
      _mathpixAppKeyKey,
      _mathpixBaseUrlKey,
    ]) {
      try {
        await _storage.delete(key: key);
      } on Object catch (_) {}
    }
  }

  Future<void> _update(
    StoredApiCredentials Function(StoredApiCredentials current) transform,
  ) async {
    final current = await loadAll();
    await _persistBundle(transform(current));
  }

  @override
  Future<String?> getDeepSeekApiKey() async =>
      (await loadAll()).deepSeekApiKey;

  @override
  Future<void> setDeepSeekApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    await _update(
      (c) => c.copyWith(
        deepSeekApiKey: trimmed.isEmpty ? null : trimmed,
        clearDeepSeek: trimmed.isEmpty,
      ),
    );
    _log.info('DeepSeek API key updated in secure storage');
  }

  @override
  Future<void> deleteDeepSeekApiKey() async {
    try {
      await _update((c) => c.copyWith(clearDeepSeek: true));
      _log.info('DeepSeek API key deleted from secure storage');
    } on AppFailure {
      rethrow;
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
  Future<void> setMathpixAppId(String appId) async {
    final trimmed = appId.trim();
    await _update(
      (c) => c.copyWith(
        mathpixAppId: trimmed.isEmpty ? null : trimmed,
        clearMathpixAppId: trimmed.isEmpty,
      ),
    );
    _log.info('Mathpix app_id updated in secure storage');
  }

  @override
  Future<void> setMathpixAppKey(String appKey) async {
    final trimmed = appKey.trim();
    await _update(
      (c) => c.copyWith(
        mathpixAppKey: trimmed.isEmpty ? null : trimmed,
        clearMathpixAppKey: trimmed.isEmpty,
      ),
    );
    _log.info('Mathpix app_key updated in secure storage');
  }

  @override
  Future<void> setMathpixBaseUrl(String? baseUrl) async {
    final trimmed = baseUrl?.trim() ?? '';
    await _update(
      (c) => c.copyWith(
        mathpixBaseUrl: trimmed.isEmpty ? null : trimmed,
        clearMathpixBaseUrl: trimmed.isEmpty,
      ),
    );
    _log.info('Mathpix base URL updated in secure storage');
  }

  @override
  Future<void> setMathpixCredentials({
    required String appId,
    required String appKey,
    String? baseUrl,
  }) async {
    final id = appId.trim();
    final key = appKey.trim();
    final url = baseUrl?.trim() ?? '';
    await _update(
      (c) => c.copyWith(
        mathpixAppId: id.isEmpty ? null : id,
        mathpixAppKey: key.isEmpty ? null : key,
        mathpixBaseUrl: url.isEmpty ? null : url,
        clearMathpixAppId: id.isEmpty,
        clearMathpixAppKey: key.isEmpty,
        clearMathpixBaseUrl: url.isEmpty,
      ),
    );
    _log.info('Mathpix credentials updated in secure storage');
  }

  @override
  Future<void> deleteMathpixCredentials() async {
    try {
      await _update((c) => c.copyWith(clearMathpix: true));
      _log.info('Mathpix credentials deleted from secure storage');
    } on AppFailure {
      rethrow;
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
