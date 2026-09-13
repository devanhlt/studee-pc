import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/data/backend/backend_config.dart';
import 'package:studee_pc/domain/repositories/credentials_repository.dart';

/// Charges exactly one solve against the activation code on the middleware.
class BackendQuotaClient {
  BackendQuotaClient({
    required CredentialsRepository credentials,
    http.Client? httpClient,
  })  : _credentials = credentials,
        _http = httpClient ?? http.Client();

  final CredentialsRepository _credentials;
  final http.Client _http;
  final AppLogger _log = AppLogger('BackendQuotaClient');

  /// Returns null on success; failure otherwise. Soft-fails when no code is set
  /// (legacy/offline) so local-only flows still work.
  Future<AppFailure?> consumeOneSolve() async {
    final code = await _credentials.getActivationCode();
    if (code == null || code.trim().isEmpty) {
      return const MissingApiKeyFailure(
        userMessage: 'Chưa có mã kích hoạt. Vào Cài đặt để nhập mã nhé.',
      );
    }
    try {
      final uri = Uri.parse(
        '${BackendConfig.baseUrl}${BackendConfig.consumeSolvePath}',
      );
      final response = await _http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer ${code.trim()}',
              'Content-Type': 'application/json',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 402) {
        return const QuotaFailure(
          userMessage: 'Mã này đã hết lượt giải. Hãy mua thêm lượt để tiếp tục.',
          code: 'quota_exhausted',
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return const AuthFailure(
          userMessage: 'Mã kích hoạt không hợp lệ hoặc đã bị thu hồi.',
          code: 'activation_invalid',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String detail = 'HTTP ${response.statusCode}';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['error'] is Map) {
            final msg = (decoded['error'] as Map)['message'];
            if (msg != null) detail = '$msg';
          }
        } on Object catch (_) {}
        return NetworkFailure(
          userMessage: 'Không trừ được lượt giải ($detail). Thử lại nhé.',
          code: 'consume_solve_http',
        );
      }
      _log.info('Consumed one solve');
      return null;
    } on Object catch (e) {
      _log.warning('consumeOneSolve failed: ${e.runtimeType}');
      return NetworkFailure(
        userMessage: 'Không trừ được lượt giải. Thử lại nhé.',
        code: 'consume_solve_failed',
        details: e.runtimeType.toString(),
      );
    }
  }
}
