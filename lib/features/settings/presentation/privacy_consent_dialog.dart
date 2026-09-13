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
        title: const Text('Cho phép Studee gửi dữ liệu'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: size.width * 0.9,
            maxHeight: size.height * 0.5,
          ),
            child: const SingleChildScrollView(
            child: Text(
              'Để giải bài và đọc chữ trong ảnh, Studee sẽ gửi dữ liệu tới '
              'máy chủ Studee (proxy DeepSeek / OCR):\n'
              '• câu hỏi bạn đang xem,\n'
              '• một vài đoạn kiến thức liên quan bạn đã lưu, và\n'
              '• ảnh hoặc PDF khi bạn dùng OCR.\n\n'
              'Mã kích hoạt chỉ lưu trên máy bạn và không được ghi vào nhật ký.\n\n'
              'Bạn đồng ý để tiếp tục?',
              style: TextStyle(height: 1.45, color: AppColors.primaryText),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Để sau'),
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
