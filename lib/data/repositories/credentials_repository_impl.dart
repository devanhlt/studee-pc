import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/data/file_storage/app_paths.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';

/// Stores secrets in ApplicationData only (obfuscated local file).
///
/// Never writes to the OS keychain / credential manager.
class CredentialsRepositoryImpl implements CredentialsRepository {
  CredentialsRepositoryImpl({required AppPaths paths}) : _paths = paths;

  static const List<int> _fileMagic = [0x53, 0x54, 0x55, 0x31]; // STU1
  static final Uint8List _obfuscationKey = Uint8List.fromList(
    sha256.convert(utf8.encode('studee.credentials.obfuscate.v1')).bytes,
  );

  final AppPaths _paths;
  final AppLogger _log = AppLogger('CredentialsRepository');

  StoredApiCredentials? _cache;
  Future<StoredApiCredentials>? _inFlight;

  @override
  Future<StoredApiCredentials> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final pending = _inFlight;
    if (pending != null) return pending;

    final future = _readFromStore();
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

  Future<StoredApiCredentials> _readFromStore() async {
    final fromFile = await _readFileBestEffort();
    return fromFile ?? const StoredApiCredentials();
  }

  Future<StoredApiCredentials?> _readFileBestEffort() async {
    try {
      final path = await _paths.credentialsFilePath();
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.length < 5) return null;
      if (!_startsWithMagic(bytes)) {
        _log.warning('Credentials file has unexpected header; ignoring');
        return null;
      }
      final payload = bytes.sublist(4);
      final jsonBytes = _xorWithKeystream(payload, _obfuscationKey);
      final decoded = jsonDecode(utf8.decode(jsonBytes));
      if (decoded is Map<String, dynamic>) {
        return StoredApiCredentials.fromJson(decoded);
      }
      if (decoded is Map) {
        return StoredApiCredentials.fromJson(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
      return null;
    } on Object catch (e) {
      _log.warning('Credentials file read failed (${e.runtimeType})');
      return null;
    }
  }

  Future<void> _persistFile(StoredApiCredentials snapshot) async {
    try {
      final path = await _paths.credentialsFilePath();
      final file = File(path);
      if (!snapshot.hasAny) {
        if (await file.exists()) {
          await file.delete();
        }
        _cache = snapshot;
        _inFlight = null;
        return;
      }

      final jsonBytes = utf8.encode(jsonEncode(snapshot.toJson()));
      final obfuscated = _xorWithKeystream(
        Uint8List.fromList(jsonBytes),
        _obfuscationKey,
      );
      final out = Uint8List(4 + obfuscated.length);
      out.setRange(0, 4, _fileMagic);
      out.setRange(4, out.length, obfuscated);
      await file.writeAsBytes(out, flush: true);
      await _restrictFilePermissionsBestEffort(path);
      _cache = snapshot;
      _inFlight = null;
    } on Object catch (e) {
      _log.severe('Failed to write credentials file', e);
      throw UnknownFailure(
        userMessage: 'Không lưu được mã kích hoạt vào dữ liệu ứng dụng.',
        code: 'credentials_file_write_failed',
        details: e.runtimeType.toString(),
      );
    }
  }

  Future<void> _update(
    StoredApiCredentials Function(StoredApiCredentials current) transform,
  ) async {
    final current = await loadAll();
    await _persistFile(transform(current));
  }

  @override
  Future<String?> getActivationCode() async =>
      (await loadAll()).activationCode;

  @override
  Future<void> setActivationCode(String code) async {
    final trimmed = code.trim();
    await _update(
      (c) => c.copyWith(
        activationCode: trimmed.isEmpty ? null : trimmed,
        clearActivationCode: trimmed.isEmpty,
        clearDeepSeek: true,
        clearMathpix: true,
      ),
    );
    _log.info('Activation code updated in ApplicationData');
  }

  @override
  Future<void> deleteActivationCode() async {
    try {
      await _update((c) => c.copyWith(clearActivationCode: true));
      _log.info('Activation code deleted from ApplicationData');
    } on AppFailure {
      rethrow;
    } on Object catch (e) {
      _log.severe('Failed to delete activation code', e);
      throw const UnknownFailure(
        userMessage: 'Không xóa được mã kích hoạt khỏi dữ liệu ứng dụng.',
        code: 'credentials_file_delete_failed',
      );
    }
  }

  @override
  Future<bool> hasActivationCode() async =>
      (await loadAll()).hasActivationCode;

  @override
  Future<String?> getDeepSeekApiKey() async => getActivationCode();

  @override
  Future<void> setDeepSeekApiKey(String apiKey) => setActivationCode(apiKey);

  @override
  Future<void> deleteDeepSeekApiKey() => deleteActivationCode();

  @override
  Future<bool> hasDeepSeekApiKey() => hasActivationCode();

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
    _log.info('Mathpix app_id updated in ApplicationData');
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
    _log.info('Mathpix app_key updated in ApplicationData');
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
    _log.info('Mathpix base URL updated in ApplicationData');
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
    _log.info('Mathpix credentials updated in ApplicationData');
  }

  @override
  Future<void> deleteMathpixCredentials() async {
    try {
      await _update((c) => c.copyWith(clearMathpix: true));
      _log.info('Mathpix credentials deleted from ApplicationData');
    } on AppFailure {
      rethrow;
    } on Object catch (e) {
      _log.severe('Failed to delete Mathpix credentials', e);
      throw const UnknownFailure(
        userMessage: 'Không xóa được khóa Mathpix khỏi dữ liệu ứng dụng.',
        code: 'credentials_file_delete_failed',
      );
    }
  }

  @override
  Future<bool> hasMathpixCredentials() async => hasActivationCode();

  static bool _startsWithMagic(Uint8List bytes) {
    if (bytes.length < 4) return false;
    for (var i = 0; i < 4; i++) {
      if (bytes[i] != _fileMagic[i]) return false;
    }
    return true;
  }

  static Uint8List _xorWithKeystream(Uint8List data, Uint8List key) {
    final out = Uint8List(data.length);
    var counter = 0;
    List<int> block = const [];
    var blockIdx = 32;
    for (var i = 0; i < data.length; i++) {
      if (blockIdx >= 32) {
        final counterBytes = ByteData(4)..setUint32(0, counter++);
        block = sha256
            .convert([...key, ...counterBytes.buffer.asUint8List()])
            .bytes;
        blockIdx = 0;
      }
      out[i] = data[i] ^ block[blockIdx++];
    }
    return out;
  }

  static Future<void> _restrictFilePermissionsBestEffort(String path) async {
    if (Platform.isWindows) return;
    try {
      await Process.run('chmod', ['600', path]);
    } on Object catch (_) {}
  }
}
