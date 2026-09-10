import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/data/mathpix/mathpix_config.dart';
import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';
import 'package:studee_pc/features/settings/application/settings_service.dart';

/// Single Keychain read for the settings screen.
final _settingsCredentialsProvider =
    FutureProvider.autoDispose<StoredApiCredentials>((ref) {
  return ref.watch(settingsServiceProvider).loadCredentials();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _deepSeekController = TextEditingController();
  final _mathpixAppIdController = TextEditingController();
  final _mathpixAppKeyController = TextEditingController();
  final _mathpixBaseUrlController = TextEditingController();
  bool _obscureDeepSeek = true;
  bool _obscureMathpixKey = true;
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _deepSeekController.dispose();
    _mathpixAppIdController.dispose();
    _mathpixAppKeyController.dispose();
    _mathpixBaseUrlController.dispose();
    super.dispose();
  }

  SettingsService get _service => ref.read(settingsServiceProvider);

  void _refreshCredentials() {
    ref.invalidate(_settingsCredentialsProvider);
  }

  Future<void> _saveDeepSeek() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await _service.saveApiKey(_deepSeekController.text);
    setState(() => _busy = false);
    result.when(
      success: (_) {
        _deepSeekController.clear();
        _refreshCredentials();
        setState(() => _status = 'Đã lưu khóa DeepSeek.');
      },
      failure: (f) => setState(() => _status = f.userMessage),
    );
  }

  Future<void> _deleteDeepSeek() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await _service.deleteApiKey();
    setState(() => _busy = false);
    result.when(
      success: (_) {
        _refreshCredentials();
        setState(() => _status = 'Đã xóa khóa DeepSeek.');
      },
      failure: (f) => setState(() => _status = f.userMessage),
    );
  }

  Future<void> _testDeepSeek() async {
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

  Future<void> _saveMathpix() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await _service.saveMathpix(
      appId: _mathpixAppIdController.text,
      appKey: _mathpixAppKeyController.text,
      baseUrl: _mathpixBaseUrlController.text.trim().isEmpty
          ? null
          : _mathpixBaseUrlController.text.trim(),
    );
    setState(() => _busy = false);
    result.when(
      success: (_) {
        _mathpixAppIdController.clear();
        _mathpixAppKeyController.clear();
        _refreshCredentials();
        setState(() => _status = 'Đã lưu thông tin Mathpix.');
      },
      failure: (f) => setState(() => _status = f.userMessage),
    );
  }

  Future<void> _deleteMathpix() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await _service.deleteMathpix();
    setState(() => _busy = false);
    result.when(
      success: (_) {
        _mathpixBaseUrlController.clear();
        _refreshCredentials();
        setState(() => _status = 'Đã xóa thông tin Mathpix.');
      },
      failure: (f) => setState(() => _status = f.userMessage),
    );
  }

  Future<void> _testMathpix() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await _service.testMathpixConnection();
    setState(() => _busy = false);
    result.when(
      success: (_) => setState(() => _status = 'Kết nối Mathpix thành công.'),
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
    final credsAsync = ref.watch(_settingsCredentialsProvider);

    String? maskedDeepSeek;
    String? maskedMathpixId;
    var hasKey = false;
    var hasMathpix = false;
    var mathpixUrl = MathpixConfig.defaultBaseUrl;
    credsAsync.whenData((c) {
      hasKey = c.hasDeepSeekApiKey;
      hasMathpix = c.hasMathpixCredentials;
      final key = c.deepSeekApiKey;
      if (key != null && key.isNotEmpty) {
        maskedDeepSeek =
            key.length <= 8 ? '••••••••' : '••••••••${key.substring(key.length - 4)}';
      }
      final id = c.mathpixAppId;
      if (id != null && id.isNotEmpty) {
        maskedMathpixId =
            id.length <= 6 ? '••••••' : '••••${id.substring(id.length - 4)}';
      }
      final url = c.mathpixBaseUrl;
      if (url != null && url.trim().isNotEmpty) {
        mathpixUrl = url.trim();
      }
    });

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
            'Khóa được lưu an toàn trên máy (Keychain / Credential Manager), '
            'không ghi vào cơ sở dữ liệu hay nhật ký.',
            style: TextStyle(color: AppColors.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (credsAsync.isLoading)
            const LinearProgressIndicator()
          else if (!hasKey)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.elevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Chưa có khóa DeepSeek — nhập bên dưới để bắt đầu giải bài.',
                style: TextStyle(color: AppColors.secondaryText, height: 1.35),
              ),
            )
          else
            Text(
              'Đã lưu: ${maskedDeepSeek ?? '••••••••'}',
              style: const TextStyle(color: AppColors.success),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _deepSeekController,
            obscureText: _obscureDeepSeek,
            decoration: InputDecoration(
              labelText: 'Khóa API DeepSeek',
              hintText: 'sk-...',
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureDeepSeek = !_obscureDeepSeek),
                icon: Icon(
                  _obscureDeepSeek
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
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
                onPressed: _busy ? null : _saveDeepSeek,
                child: const Text('Lưu'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _testDeepSeek,
                child: const Text('Kiểm tra kết nối'),
              ),
              TextButton(
                onPressed: _busy ? null : _deleteDeepSeek,
                child: const Text(
                  'Xóa khóa',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Mathpix OCR',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dùng để nhận dạng chữ/công thức từ ảnh hoặc PDF. Lấy App ID và '
            'App Key tại console.mathpix.com.',
            style: TextStyle(color: AppColors.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (credsAsync.isLoading)
            const LinearProgressIndicator()
          else if (!hasMathpix)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.elevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Chưa cấu hình OCR — nhập App ID và App Key để nhận dạng ảnh.',
                style: TextStyle(color: AppColors.secondaryText, height: 1.35),
              ),
            )
          else
            Text(
              'Đã lưu App ID: ${maskedMathpixId ?? '••••'}',
              style: const TextStyle(color: AppColors.success),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _mathpixAppIdController,
            decoration: const InputDecoration(
              labelText: 'App ID',
              hintText: 'your_app_id',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mathpixAppKeyController,
            obscureText: _obscureMathpixKey,
            decoration: InputDecoration(
              labelText: 'App Key',
              hintText: '••••••••',
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureMathpixKey = !_obscureMathpixKey),
                icon: Icon(
                  _obscureMathpixKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mathpixBaseUrlController,
            decoration: InputDecoration(
              labelText: 'Địa chỉ máy chủ (tuỳ chọn)',
              hintText: mathpixUrl,
              helperText:
                  'Để trống nếu dùng Mathpix mặc định. Chỉ đổi khi bạn có máy chủ riêng.',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: _busy ? null : _saveMathpix,
                child: const Text('Lưu'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _testMathpix,
                child: const Text('Kiểm tra'),
              ),
              TextButton(
                onPressed: _busy ? null : _deleteMathpix,
                child: const Text(
                  'Xóa',
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
                        (_status!.startsWith('Đã') &&
                            !_status!.contains('Thoát'))
                    ? AppColors.success
                    : _status!.contains('Thoát') ||
                            _status!.contains('Đặt lại')
                        ? AppColors.secondaryText
                        : AppColors.error,
                height: 1.4,
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
              'Nếu đã bật quyền trong Cài đặt hệ thống nhưng vẫn không chụp '
              'được: nhấn Đặt lại bên dưới, thoát hẳn Studee, mở lại, rồi '
              'cho phép khi macOS hỏi.',
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
                        ? 'Quyền ghi màn hình: đã cho phép'
                        : 'Quyền ghi màn hình: chưa cho phép';
                return Text(
                  label,
                  style: TextStyle(
                    color: ok == true ? AppColors.success : AppColors.secondaryText,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _resetScreenCapture,
              child: const Text('Đặt lại quyền ghi màn hình'),
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
            'Ảnh/PDF dùng nhận dạng chữ được gửi tới dịch vụ OCR. '
            'Khi giải bài, DeepSeek chỉ nhận câu hỏi hiện tại và vài đoạn '
            'kiến thức đã lưu liên quan. Khóa API không ghi vào nhật ký.',
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
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
