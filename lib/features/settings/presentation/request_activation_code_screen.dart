import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/data/backend/checkout_client.dart';
import 'package:studee_pc/features/settings/application/activation_request_config.dart';
import 'package:studee_pc/features/settings/application/quota_revision.dart';
import 'package:studee_pc/features/settings/presentation/settings_screen.dart';

/// Creates a VietQR checkout and waits (SSE) for SePay to confirm payment.
class RequestActivationCodeScreen extends ConsumerStatefulWidget {
  const RequestActivationCodeScreen({super.key});

  @override
  ConsumerState<RequestActivationCodeScreen> createState() =>
      _RequestActivationCodeScreenState();
}

class _RequestActivationCodeScreenState
    extends ConsumerState<RequestActivationCodeScreen> {
  ActivationRequestPlan _plan = ActivationRequestPlan.pro;
  CheckoutSession? _session;
  StreamSubscription<CheckoutStatus>? _watchSub;
  String _statusLabel = '';
  String? _activationCode;
  DateTime? _codeExpiresAt;
  String? _error;
  bool _busy = false;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void dispose() {
    _watchSub?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    void tick() {
      final left = expiresAt.difference(DateTime.now());
      if (!mounted) return;
      setState(() {
        _remaining = left.isNegative ? Duration.zero : left;
      });
      if (left.isNegative) {
        _countdownTimer?.cancel();
      }
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _createCheckout() async {
    setState(() {
      _busy = true;
      _error = null;
      _activationCode = null;
      _codeExpiresAt = null;
      _statusLabel = 'Đang tạo mã QR…';
    });

    final client = ref.read(checkoutClientProvider);
    final result = await client.createCheckout(plan: _plan);

    if (!mounted) return;

    await result.when(
      success: (session) async {
        setState(() {
          _session = session;
          _busy = false;
          _statusLabel = 'Đang chờ thanh toán…';
        });
        _startCountdown(session.expiresAt);
        await _watchSub?.cancel();
        _watchSub = client.watchStatus(session).listen(
          _onStatus,
          onError: (Object e) {
            if (!mounted) return;
            setState(() {
              _error = 'Mất kết nối trạng thái thanh toán. Thử lại nhé.';
            });
          },
        );
      },
      failure: (f) async {
        setState(() {
          _busy = false;
          _error = f.userMessage;
          _statusLabel = '';
        });
      },
    );
  }

  Future<void> _onStatus(CheckoutStatus status) async {
    if (!mounted) return;

    if (status.status == 'pending' || status.status == 'claimed') {
      setState(() {
        _statusLabel = status.status == 'claimed'
            ? 'Đã nhận thanh toán, đang cấp mã…'
            : 'Đang chờ thanh toán…';
      });
      return;
    }

    if (status.isExpired) {
      await _watchSub?.cancel();
      _watchSub = null;
      setState(() {
        _statusLabel = 'Hết hạn thanh toán';
        _error = 'Phiên QR đã hết hạn. Tạo mã QR mới nhé.';
      });
      return;
    }

    if (status.isPaid) {
      await _watchSub?.cancel();
      _watchSub = null;
      final code = status.activationCode?.trim();
      if (code == null || code.isEmpty) {
        setState(() {
          _statusLabel = 'Đã thanh toán';
          _error = 'Đã nhận tiền nhưng chưa lấy được mã. Thử mở lại Cài đặt.';
        });
        return;
      }

      setState(() {
        _statusLabel = 'Đã kích hoạt';
        _activationCode = code;
        _codeExpiresAt = status.codeExpiresAt ??
            DateTime.now().add(Duration(days: _plan.validityDays));
      });

      final save = await ref
          .read(settingsServiceProvider)
          .saveActivationCode(code);
      if (!mounted) return;
      save.when(
        success: (_) {
          ref.invalidate(settingsCredentialsProvider);
          ref.read(quotaRevisionProvider.notifier).state++;
        },
        failure: (f) {
          setState(() => _error = f.userMessage);
        },
      );
    }
  }

  void _resetToPick() {
    _watchSub?.cancel();
    _watchSub = null;
    _countdownTimer?.cancel();
    setState(() {
      _session = null;
      _activationCode = null;
      _codeExpiresAt = null;
      _error = null;
      _statusLabel = '';
      _remaining = Duration.zero;
    });
  }

  String get _countdownLabel {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _waitingTitle {
    final status = _statusLabel.trim();
    if (status.isEmpty ||
        status == 'Đang chờ thanh toán…' ||
        status == 'Đang chờ thanh toán…') {
      return 'Đang chờ thanh toán…';
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return StudeePageScaffold(
      atmosphereIntensity: AppLayout.atmospherePage,
      topBar: StudeeGlassAppBar(
        title: 'Yêu cầu mã',
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () {
            if (session != null && _activationCode == null) {
              _resetToPick();
              return;
            }
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: AppLayout.pageInsets(context),
        children: [
          StudeeGlass(
            padding: const EdgeInsets.all(AppLayout.gapLg),
            child: session == null ? _buildPickStep() : _buildPayStep(session),
          ),
          if (session == null) ...[
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _createCheckout,
              child: Text(_busy ? 'Đang mở…' : 'Thanh toán ngay'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPickStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < ActivationRequestConfig.plans.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
          ],
          _buildPlanOption(ActivationRequestConfig.plans[i]),
        ],
      ],
    );
  }

  Widget _buildPlanOption(ActivationRequestPlan plan) {
    final selected = plan == _plan;
    final isPopular = plan == ActivationRequestPlan.pro;
    const detailStyle = TextStyle(
      color: AppColors.secondaryText,
      fontSize: 13,
      height: 1.4,
    );

    return InkWell(
      borderRadius: AppLayout.controlBorder,
      onTap: _busy ? null : () => setState(() => _plan = plan),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _PlanRadio(selected: selected),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isPopular ? AppColors.accent : null,
                          ),
                        ),
                      ),
                      if (isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius:
                                BorderRadius.circular(AppLayout.radiusPill),
                          ),
                          child: const Text(
                            'Phổ biến',
                            style: TextStyle(
                              color: AppColors.onAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.tokensLabel,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(plan.amountLabel, style: detailStyle),
                  const SizedBox(height: 2),
                  Text(
                    'Thời hạn: ${plan.validityDays} ngày kể từ ngày mua',
                    style: detailStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayStep(CheckoutSession session) {
    if (_activationCode != null) {
      return _buildActivatedCode();
    }

    final amountLabel =
        ActivationRequestConfig.formatVnd(session.amountVnd);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Chuyển $amountLabel · gói ${session.plan}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.16),
            borderRadius: AppLayout.controlBorder,
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.7),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Vui lòng không rời khỏi. Mã sẽ được kích hoạt khi '
                    'thanh toán thành công.',
                    style: TextStyle(
                      color: AppColors.warning,
                      height: 1.4,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Text(
                _waitingTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              if (_remaining > Duration.zero) ...[
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Còn ',
                    style: TextStyle(
                      color: AppColors.secondaryText.withValues(alpha: 0.95),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppLayout.radiusPill,
                            ),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.85),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: Text(
                              _countdownLabel,
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: AppLayout.controlBorder,
                child: ColoredBox(
                  color: Colors.white,
                  child: Image.network(
                    session.qrUrl,
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Không tải được QR.\n'
                              'Chuyển thủ công:\n'
                              '${session.bank} · ${session.account}\n'
                              'ND: ${session.payCode}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Nội dung chuyển khoản',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Material(
          color: AppColors.elevated,
          borderRadius: AppLayout.controlBorder,
          child: InkWell(
            borderRadius: AppLayout.controlBorder,
            onTap: () => _copy(
              'Đã sao chép nội dung chuyển khoản.',
              session.payCode,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      session.payCode,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sao chép',
                    onPressed: () => _copy(
                      'Đã sao chép nội dung chuyển khoản.',
                      session.payCode,
                    ),
                    icon: const Icon(AppIcons.copy),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: _resetToPick,
          child: const Text('Huỷ / chọn gói khác'),
        ),
      ],
    );
  }

  Widget _buildActivatedCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mã kích hoạt',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'Vui lòng lưu lại mã kích hoạt này để dùng lại khi cần.',
          style: TextStyle(
            color: AppColors.secondaryText.withValues(alpha: 0.95),
            height: 1.4,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: AppColors.elevated,
          borderRadius: AppLayout.controlBorder,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _activationCode!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sao chép mã',
                  onPressed: () => _copy(
                    'Đã sao chép mã kích hoạt.',
                    _activationCode!,
                  ),
                  icon: const Icon(AppIcons.copy),
                ),
              ],
            ),
          ),
        ),
        if (_codeExpiresAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Hết hạn: ${ActivationRequestConfig.formatDate(_codeExpiresAt!)}',
            style: TextStyle(
              color: AppColors.secondaryText.withValues(alpha: 0.95),
              fontSize: 13,
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.pop(),
          child: const Text('Xong'),
        ),
      ],
    );
  }
}

class _PlanRadio extends StatelessWidget {
  const _PlanRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.accent : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.borderStrong,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.onAccent,
            )
          : null,
    );
  }
}
