import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/features/settings/application/activation_request_config.dart';

/// Collects a bank-transfer request so the user can receive an activation code.
class RequestActivationCodeScreen extends StatefulWidget {
  const RequestActivationCodeScreen({super.key});

  @override
  State<RequestActivationCodeScreen> createState() =>
      _RequestActivationCodeScreenState();
}

class _RequestActivationCodeScreenState
    extends State<RequestActivationCodeScreen> {
  final _contactController = TextEditingController();
  late final String _transferCode;
  ActivationRequestPlan _plan = ActivationRequestPlan.basic;
  bool? _qrAssetExists;

  @override
  void initState() {
    super.initState();
    _transferCode = _generateTransferCode();
    _probeQrAsset();
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _probeQrAsset() async {
    try {
      await rootBundle.load(ActivationRequestConfig.paymentQrAsset);
      if (mounted) setState(() => _qrAssetExists = true);
    } on Object catch (_) {
      if (mounted) setState(() => _qrAssetExists = false);
    }
  }

  static String _generateTransferCode({int length = 8}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)])
        .join();
  }

  Future<void> _copyTransferCode() async {
    await Clipboard.setData(ClipboardData(text: _transferCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép nội dung chuyển khoản.')),
    );
  }

  Future<void> _onComplete() async {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhập email hoặc số Zalo để nhận mã kích hoạt.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận yêu cầu mã'),
        content: Text(
          'Bạn đã chuyển khoản ${_plan.amountLabel} cho mã ${_plan.label} '
          '(${_plan.solvesLabel}) với nội dung $_transferCode?\n\n'
          'Mã kích hoạt sẽ được gửi tới:\n$contact',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudeePageScaffold(
      topBar: const StudeeGlassAppBar(title: 'Yêu cầu mã'),
      body: ListView(
        padding: AppLayout.pageInsets(context),
        children: [
          StudeeGlass(
            borderRadius: 16,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Chọn hạn mức',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mỗi gói là một mã mới kèm số lượt giải. Hết lượt thì mua mã '
                  'khác — không tính theo tháng.',
                  style: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.95),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ActivationRequestPlan>(
                  initialValue: _plan,
                  decoration: const InputDecoration(
                    labelText: 'Gói / số lượt',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final plan in ActivationRequestConfig.plans)
                      DropdownMenuItem(
                        value: plan,
                        child: Text(plan.dropdownLabel),
                      ),
                  ],
                  onChanged: (plan) {
                    if (plan == null) return;
                    setState(() => _plan = plan);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Quét mã QR và chuyển ${_plan.amountLabel} để nhận mã '
                  '${_plan.label} (${_plan.solvesLabel}). Dán đúng nội dung '
                  'bên dưới để đối soát.',
                  style: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.95),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                Center(child: _buildQr()),
                const SizedBox(height: 24),
                const Text(
                  'Nội dung chuyển khoản',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _copyTransferCode,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _transferCode,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Sao chép',
                            onPressed: _copyTransferCode,
                            icon: const Icon(Icons.copy_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chỉ chữ in hoa và số · chạm để sao chép',
                  style: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _contactController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Email / số Zalo nhận mã',
                    hintText: 'vd. ban@email.com hoặc 09xxxxxxxx',
                  ),
                  onSubmitted: (_) => _onComplete(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _onComplete,
                  child: const Text('Hoàn thành'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQr() {
    const size = 220.0;
    if (_qrAssetExists == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          ActivationRequestConfig.paymentQrAsset,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: QrImageView(
        key: ValueKey(_plan),
        data: ActivationRequestConfig.qrPayloadFor(
          plan: _plan,
          transferCode: _transferCode,
        ),
        version: QrVersions.auto,
        size: size - 24,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF111214),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF111214),
        ),
      ),
    );
  }
}
