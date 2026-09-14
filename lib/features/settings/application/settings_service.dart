import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/data/backend/backend_config.dart';
import 'package:studee_pc/data/mathpix/mathpix_client.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';
import 'package:studee_pc/domain/repositories/deepseek_client.dart';
import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';

/// Activation entitlement returned by the middleware.
class EntitlementInfo {
  const EntitlementInfo({
    required this.plan,
    required this.maxSolves,
    required this.solvesUsed,
    required this.remaining,
    required this.status,
  });

  final String plan;
  final int maxSolves;
  final int solvesUsed;
  final int remaining;
  final String status;

  factory EntitlementInfo.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return EntitlementInfo(
      plan: '${json['plan'] ?? ''}',
      maxSolves: asInt(json['max_solves']),
      solvesUsed: asInt(json['solves_used']),
      remaining: asInt(json['remaining']),
      status: '${json['status'] ?? ''}',
    );
  }
}

/// Settings workflow: activation code + entitlement check.
class SettingsService {
  SettingsService({
    required CredentialsRepository credentials,
    required DeepSeekClient deepSeek,
    required MathpixClient mathpix,
    http.Client? httpClient,
  })  : _credentials = credentials,
        _deepSeek = deepSeek,
        _mathpix = mathpix,
        _http = httpClient ?? http.Client();

  final CredentialsRepository _credentials;
  // Kept for DI compatibility with existing providers.
  // ignore: unused_field
  final DeepSeekClient _deepSeek;
  // ignore: unused_field
  final MathpixClient _mathpix;
  final http.Client _http;
  final AppLogger _log = AppLogger('SettingsService');

  Future<StoredApiCredentials> loadCredentials() => _credentials.loadAll();

  Future<bool> hasKey() async => (await loadCredentials()).hasActivationCode;

  Future<bool> hasMathpix() async => hasKey();

  Future<String?> maskedActivationPreview() async {
    final code = (await loadCredentials()).activationCode;
    if (code == null || code.isEmpty) return null;
    if (code.length <= 8) return '••••••••';
    return '••••${code.substring(code.length - 4)}';
  }

  Future<String?> maskedKeyPreview() => maskedActivationPreview();

  Future<Result<void>> saveActivationCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return const Failure(
        ValidationFailure(
          userMessage: 'Nhập mã kích hoạt',
          code: 'activation_code_empty',
        ),
      );
    }
    try {
      await _credentials.setActivationCode(trimmed);
      _log.info('Activation code saved');
      return const Success(null);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        UnknownFailure(
          userMessage: 'Không lưu được mã kích hoạt.',
          code: 'save_activation_code_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<void>> saveApiKey(String apiKey) => saveActivationCode(apiKey);

  Future<Result<void>> deleteActivationCode() async {
    try {
      await _credentials.deleteActivationCode();
      _log.info('Activation code deleted');
      return const Success(null);
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        UnknownFailure(
          userMessage: 'Không xóa được mã kích hoạt.',
          code: 'delete_activation_code_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<void>> deleteApiKey() => deleteActivationCode();

  Future<Result<void>> deleteMathpix() => deleteActivationCode();

  Future<Result<EntitlementInfo>> fetchEntitlement() async {
    final code = (await loadCredentials()).activationCode;
    if (code == null || code.isEmpty) {
      return const Failure(
        MissingApiKeyFailure(
          userMessage: 'Nhập mã kích hoạt',
        ),
      );
    }
    try {
      final uri = Uri.parse(
        '${BackendConfig.baseUrl}${BackendConfig.entitlementPath}',
      );
      final response = await _http
          .get(
            uri,
            headers: {'Authorization': 'Bearer $code'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401 || response.statusCode == 403) {
        return const Failure(
          AuthFailure(
            userMessage: 'Mã kích hoạt không hợp lệ hoặc đã bị thu hồi.',
            code: 'activation_invalid',
          ),
        );
      }
      if (response.statusCode == 402) {
        return const Failure(
          QuotaFailure(
            userMessage: 'Đã hết token của mã này.',
            code: 'quota_exhausted',
          ),
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(
          NetworkFailure(
            userMessage: 'Không kiểm tra được mã (HTTP ${response.statusCode}).',
            code: 'entitlement_http',
          ),
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return const Failure(
          UnknownFailure(
            userMessage: 'Phản hồi entitlement không hợp lệ.',
            code: 'entitlement_bad_json',
          ),
        );
      }
      return Success(
        EntitlementInfo.fromJson(Map<String, dynamic>.from(decoded)),
      );
    } on AppFailure catch (f) {
      return Failure(f);
    } on Object catch (e) {
      return Failure(
        NetworkFailure(
          userMessage: 'Không kiểm tra được mã kích hoạt.',
          code: 'entitlement_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<void>> testConnection() async {
    final result = await fetchEntitlement();
    return result.when(
      success: (info) {
        _log.info(
          'Entitlement OK plan=${info.plan} remaining=${info.remaining}',
        );
        return const Success(null);
      },
      failure: Failure.new,
    );
  }

  Future<Result<void>> testMathpixConnection() => testConnection();
}
