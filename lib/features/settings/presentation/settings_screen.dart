import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/features/settings/application/settings_service.dart';

final _hasApiKeyProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(settingsServiceProvider).hasKey();
});

final _maskedKeyProvider = FutureProvider.autoDispose<String?>((ref) {
  return ref.watch(settingsServiceProvider).maskedKeyPreview();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  SettingsService get _service => ref.read(settingsServiceProvider);

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await _service.saveApiKey(_controller.text);
    setState(() => _busy = false);
    result.when(
      success: (_) {
        _controller.clear();
        ref.invalidate(_hasApiKeyProvider);
        ref.invalidate(_maskedKeyProvider);
        setState(() => _status = 'Đã lưu khóa API.');
      },
      failure: (f) => setState(() => _status = f.userMessage),
    );
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await _service.deleteApiKey();
    setState(() => _busy = false);
    result.when(
      success: (_) {
        ref.invalidate(_hasApiKeyProvider);
        ref.invalidate(_maskedKeyProvider);
        setState(() => _status = 'Đã xóa khóa API.');
      },
      failure: (f) => setState(() => _status = f.userMessage),
    );
  }

  Future<void> _test() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await _service.testConnection();
    setState(() => _busy = false);
    result.when(
      success: (_) => setState(() => _status = 'Kết nối DeepSeek thành công.'),
      failure: (f) => setState(() => _status = f.userMessage),
    );
  }

  Future<void> _resetScreenCapture() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await ref
          .read(desktopIntegrationProvider)
          .resetAndRequestScreenCaptureAccess();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status =
            'Đã đặt lại quyền Ghi màn hình. Thoát hẳn Studee (Dock → Quit), '
            'mở lại app, thử chụp một lần và cho phép khi được hỏi.';
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status =
            'Không đặt lại được tự động. Chạy trong Terminal: '
            './scripts/reset_screen_capture_permission.sh';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(_hasApiKeyProvider);
    final masked = ref.watch(_maskedKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: AppLayout.pageInsets(context),
        children: [
          const Text(
            'DeepSeek API',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Khóa lưu trong kho bảo mật hệ thống (Keychain / Credential '
            'Manager). Không ghi vào CSDL hay nhật ký.',
            style: TextStyle(color: AppColors.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 16),
          hasKey.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (ok) {
              if (!ok) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'Nhập khóa API DeepSeek',
                    style: TextStyle(color: AppColors.warning),
                  ),
                );
              }
              return Text(
                'Đã lưu: ${masked.asData?.value ?? '••••••••'}',
                style: const TextStyle(color: AppColors.success),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Khóa API DeepSeek',
              hintText: 'sk-...',
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Lưu'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _test,
                child: const Text('Kiểm tra kết nối'),
              ),
              TextButton(
                onPressed: _busy ? null : _delete,
                child: const Text(
                  'Xóa khóa',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_status != null) ...[
            const SizedBox(height: 16),
            Text(
              _status!,
              style: TextStyle(
                color: _status!.contains('thành công') ||
                        _status!.startsWith('Đã')
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ],
          if (Platform.isMacOS) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Ghi màn hình (macOS)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nếu Cài đặt hệ thống hiện đã bật nhưng app vẫn xin quyền / '
              'không chụp được: quyền bị “kẹt” (thường sau khi cài lại DMG '
              'hoặc chạy song song bản Debug). Đặt lại quyền bên dưới, '
              'thoát hẳn Studee, mở lại, rồi cho phép khi được hỏi.',
              style: TextStyle(
                color: AppColors.secondaryText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<bool>(
              future: ref
                  .read(desktopIntegrationProvider)
                  .isScreenCaptureAllowed(),
              builder: (context, snap) {
                final ok = snap.data;
                final label = ok == null
                    ? 'Đang kiểm tra…'
                    : ok
                        ? 'Trạng thái API: được phép'
                        : 'Trạng thái API: chưa hiệu lực (dù Cài đặt có thể hiện bật)';
                return Text(
                  label,
                  style: TextStyle(
                    color: ok == true ? AppColors.success : AppColors.warning,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => ref
                          .read(desktopIntegrationProvider)
                          .openScreenCaptureSettings(),
                  child: const Text('Mở Cài đặt hệ thống'),
                ),
                FilledButton.tonal(
                  onPressed: _busy ? null : _resetScreenCapture,
                  child: const Text('Đặt lại quyền Ghi màn hình'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Quyền riêng tư',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Trước lần gọi API đầu tiên: chỉ câu hỏi hiện tại và một gói '
            'bằng chứng nhỏ (3–8 đơn vị kiến thức) được gửi tới DeepSeek. '
            'Tài liệu gốc, ảnh và OCR đầy đủ chạy cục bộ. Khóa API không '
            'bao giờ được ghi nhật ký.',
            style: TextStyle(
              color: AppColors.secondaryText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Phím tắt',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Platform.isMacOS
                ? 'Trong môn học:\n'
                    '  ⌘1 Giải · ⌘2 Kiến thức · ⌘3 Lịch sử\n'
                    '  ⌘G / ⌘↵ Giải (tab Giải)'
                : 'Trong môn học:\n'
                    '  Ctrl+1 Giải · Ctrl+2 Kiến thức · Ctrl+3 Lịch sử\n'
                    '  Ctrl+G / Ctrl+↵ Giải (tab Giải)',
            style: const TextStyle(
              color: AppColors.secondaryText,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
