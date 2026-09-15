import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:studee_pc/core/errors/app_failure.dart';
import 'package:studee_pc/core/logging/app_logger.dart';
import 'package:studee_pc/core/result/result.dart';
import 'package:studee_pc/data/backend/backend_config.dart';

class CheckoutSession {
  const CheckoutSession({
    required this.id,
    required this.clientSecret,
    required this.payCode,
    required this.plan,
    required this.amountVnd,
    required this.qrUrl,
    required this.bank,
    required this.account,
    required this.accountHolder,
    required this.expiresAt,
  });

  final String id;
  final String clientSecret;
  final String payCode;
  final String plan;
  final int amountVnd;
  final String qrUrl;
  final String bank;
  final String account;
  final String accountHolder;
  final DateTime expiresAt;

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    return CheckoutSession(
      id: '${json['id']}',
      clientSecret: '${json['client_secret']}',
      payCode: '${json['pay_code']}',
      plan: '${json['plan']}',
      amountVnd: (json['amount_vnd'] as num).toInt(),
      qrUrl: '${json['qr_url']}',
      bank: '${json['bank']}',
      account: '${json['account']}',
      accountHolder: '${json['account_holder']}',
      expiresAt: DateTime.parse('${json['expires_at']}').toLocal(),
    );
  }
}

class CheckoutStatus {
  const CheckoutStatus({
    required this.status,
    this.activationCode,
    this.plan,
    this.amountVnd,
    this.payCode,
    this.expiresAt,
    this.codeExpiresAt,
  });

  /// pending | claimed | paid | expired
  final String status;
  final String? activationCode;
  final String? plan;
  final int? amountVnd;
  final String? payCode;
  final DateTime? expiresAt;
  final DateTime? codeExpiresAt;

  bool get isPaid => status == 'paid';
  bool get isExpired => status == 'expired';
  bool get isTerminal => isPaid || isExpired;

  factory CheckoutStatus.fromJson(Map<String, dynamic> json) {
    DateTime? expires;
    final rawExpires = json['expires_at'];
    if (rawExpires is String && rawExpires.isNotEmpty) {
      expires = DateTime.tryParse(rawExpires)?.toLocal();
    }
    DateTime? codeExpires;
    final rawCodeExpires = json['code_expires_at'];
    if (rawCodeExpires is String && rawCodeExpires.isNotEmpty) {
      codeExpires = DateTime.tryParse(rawCodeExpires)?.toLocal();
    }
    return CheckoutStatus(
      status: '${json['status']}',
      activationCode: json['activation_code'] as String?,
      plan: json['plan'] as String?,
      amountVnd: json['amount_vnd'] is num
          ? (json['amount_vnd'] as num).toInt()
          : null,
      payCode: json['pay_code'] as String?,
      expiresAt: expires,
      codeExpiresAt: codeExpires,
    );
  }
}

/// Creates checkout sessions and watches payment status via SSE (+ poll fallback).
class CheckoutClient {
  CheckoutClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  final AppLogger _log = AppLogger('CheckoutClient');

  Future<Result<CheckoutSession>> createCheckout({
    required String planId,
    String? contact,
  }) async {
    try {
      final uri = Uri.parse(
        '${BackendConfig.baseUrl}${BackendConfig.checkoutPath}',
      );
      final body = <String, dynamic>{'plan': planId};
      final trimmed = contact?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        body['contact'] = trimmed;
      }

      final response = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 503) {
        return const Failure(
          NetworkFailure(
            userMessage:
                'Chưa cấu hình thanh toán trên máy chủ. Thử lại sau nhé.',
            code: 'vietqr_not_configured',
          ),
        );
      }
      if (response.statusCode == 429) {
        return const Failure(
          RateLimitFailure(
            userMessage: 'Bạn tạo QR hơi nhanh. Chờ một chút rồi thử lại.',
            code: 'checkout_rate_limited',
          ),
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(
          NetworkFailure(
            userMessage: 'Không tạo được mã QR thanh toán. Thử lại nhé.',
            code: 'checkout_create_http',
            details: 'HTTP ${response.statusCode}',
          ),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const Failure(
          NetworkFailure(
            userMessage: 'Phản hồi máy chủ không hợp lệ.',
            code: 'checkout_create_bad_json',
          ),
        );
      }
      return Success(CheckoutSession.fromJson(decoded));
    } on Object catch (e) {
      _log.warning('createCheckout failed: ${e.runtimeType}');
      return Failure(
        NetworkFailure(
          userMessage: 'Không tạo được mã QR thanh toán. Thử lại nhé.',
          code: 'checkout_create_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  Future<Result<CheckoutStatus>> fetchStatus(CheckoutSession session) async {
    try {
      final uri = Uri.parse(
        '${BackendConfig.baseUrl}${BackendConfig.checkoutPath}/${session.id}',
      ).replace(queryParameters: {'secret': session.clientSecret});

      final response = await _http
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Failure(
          NetworkFailure(
            userMessage: 'Không kiểm tra được trạng thái thanh toán.',
            code: 'checkout_status_http',
            details: 'HTTP ${response.statusCode}',
          ),
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const Failure(
          NetworkFailure(
            userMessage: 'Phản hồi máy chủ không hợp lệ.',
            code: 'checkout_status_bad_json',
          ),
        );
      }
      return Success(CheckoutStatus.fromJson(decoded));
    } on Object catch (e) {
      _log.warning('fetchStatus failed: ${e.runtimeType}');
      return Failure(
        NetworkFailure(
          userMessage: 'Không kiểm tra được trạng thái thanh toán.',
          code: 'checkout_status_failed',
          details: e.runtimeType.toString(),
        ),
      );
    }
  }

  /// SSE watch with reconnect, then polling fallback until [session.expiresAt].
  Stream<CheckoutStatus> watchStatus(CheckoutSession session) async* {
    var reconnects = 0;
    while (DateTime.now().isBefore(session.expiresAt)) {
      if (reconnects >= 3) {
        yield* _pollUntilDone(session);
        return;
      }

      try {
        await for (final status in _sseOnce(session)) {
          yield status;
          if (status.isTerminal) return;
          reconnects = 0;
        }
      } on Object catch (e) {
        _log.warning('SSE watch interrupted: ${e.runtimeType}');
      }

      reconnects += 1;
      if (!DateTime.now().isBefore(session.expiresAt)) break;
      await Future<void>.delayed(
        Duration(milliseconds: 500 * reconnects.clamp(1, 4)),
      );
    }

    yield const CheckoutStatus(status: 'expired');
  }

  Stream<CheckoutStatus> _sseOnce(CheckoutSession session) async* {
    final uri = Uri.parse(
      '${BackendConfig.baseUrl}${BackendConfig.checkoutPath}/${session.id}/events',
    ).replace(queryParameters: {'secret': session.clientSecret});

    final request = http.Request('GET', uri);
    request.headers['Accept'] = 'text/event-stream';
    final response = await _http.send(request).timeout(
          Duration(
            seconds: session.expiresAt
                .difference(DateTime.now())
                .inSeconds
                .clamp(5, 300),
          ),
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('SSE HTTP ${response.statusCode}');
    }

    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk;
      while (true) {
        final sep = buffer.indexOf('\n\n');
        if (sep < 0) break;
        final event = buffer.substring(0, sep);
        buffer = buffer.substring(sep + 2);
        final status = _parseSseEvent(event);
        if (status != null) {
          yield status;
          if (status.isTerminal) return;
        }
      }
    }
  }

  Stream<CheckoutStatus> _pollUntilDone(CheckoutSession session) async* {
    _log.info('Falling back to checkout status polling');
    while (DateTime.now().isBefore(session.expiresAt)) {
      final result = await fetchStatus(session);
      final status = result.valueOrNull;
      if (status != null) {
        yield status;
        if (status.isTerminal) return;
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    yield const CheckoutStatus(status: 'expired');
  }

  /// Visible for unit tests.
  static CheckoutStatus? parseSseEventForTest(String event) =>
      _parseSseEvent(event);

  static CheckoutStatus? _parseSseEvent(String event) {
    final lines = event.split('\n');
    final dataLines = <String>[];
    for (final line in lines) {
      if (line.startsWith(':')) continue;
      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
      }
    }
    if (dataLines.isEmpty) return null;
    try {
      final decoded = jsonDecode(dataLines.join('\n'));
      if (decoded is! Map<String, dynamic>) return null;
      return CheckoutStatus.fromJson(decoded);
    } on Object {
      return null;
    }
  }
}
