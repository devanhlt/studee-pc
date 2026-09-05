import 'package:flutter/material.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/features/settings/application/privacy_consent_store.dart';

/// Shows a one-time Vietnamese privacy notice before the first DeepSeek call.
Future<bool> ensureDeepSeekPrivacyConsent(
  BuildContext context, {
  required PrivacyConsentStore store,
}) async {
  if (await store.isAcknowledged()) return true;
  if (!context.mounted) return false;

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Gửi dữ liệu tới DeepSeek'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.9,
            maxHeight: size.height * 0.5,
          ),
          child: const SingleChildScrollView(
            child: Text(
              'Ứng dụng sẽ gửi tới DeepSeek chỉ:\n'
              '• câu hỏi hiện tại (sau OCR/chuẩn hóa), và\n'
              '• một gói bằng chứng nhỏ (3–8 đơn vị kiến thức đã xếp hạng).\n\n'
              'Tài liệu gốc, PDF, ảnh chụp màn hình và OCR đầy đủ luôn xử lý '
              'cục bộ trên máy của bạn. Khóa API không bao giờ được ghi nhật ký.\n\n'
              'Bạn có muốn tiếp tục không?',
              style: TextStyle(height: 1.45, color: AppColors.primaryText),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đồng ý và tiếp tục'),
          ),
        ],
      );
    },
  );

  if (accepted == true) {
    await store.acknowledge();
    return true;
  }
  return false;
}
