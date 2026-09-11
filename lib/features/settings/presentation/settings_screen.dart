import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';
import 'package:studee_pc/features/settings/application/settings_service.dart';

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

  Color get _statusColor {
    final s = _status ?? '';
    if (s.contains('thành công') ||
        (s.startsWith('Đã') && !s.contains('Thoát') && !s.contains('Đặt lại'))) {
      return AppColors.success;
    }
    if (s.contains('Thoát') || s.contains('Đặt lại')) {
      return AppColors.secondaryText;
    }
    return AppColors.error;
  }

  Future<void> _saveDeepSeek() async {
    if (_deepSeekController.text.trim().isEmpty) {
      setState(() => _status = 'Nhập khóa DeepSeek.');
      return;
    }
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
    if (_mathpixAppIdController.text.trim().isEmpty ||
        _mathpixAppKeyController.text.trim().isEmpty) {
      setState(() => _status = 'Nhập App ID và App Key.');
      return;
    }
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
        setState(() => _status = 'Đã lưu Mathpix.');
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
        setState(() => _status = 'Đã xóa Mathpix.');
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
        _status = 'Đã đặt lại. Thoát hẳn Studee rồi mở lại để cấp quyền.';
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = 'Không đặt lại được. Thử lại hoặc cấp quyền trong Hệ thống.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final credsAsync = ref.watch(_settingsCredentialsProvider);

    var hasKey = false;
    var hasMathpix = false;
    String? maskedDeepSeek;
    String? maskedMathpixId;
    credsAsync.whenData((c) {
      hasKey = c.hasDeepSeekApiKey;
      hasMathpix = c.hasMathpixCredentials;
      final key = c.deepSeekApiKey;
      if (key != null && key.isNotEmpty) {
        maskedDeepSeek = key.length <= 8
            ? '••••••••'
            : '••••${key.substring(key.length - 4)}';
      }
      final id = c.mathpixAppId;
      if (id != null && id.isNotEmpty) {
        maskedMathpixId = id.length <= 6
            ? '••••••'
            : '••••${id.substring(id.length - 4)}';
      }
    });

    return StudeePageScaffold(
      topBar: const StudeeGlassAppBar(title: 'Cài đặt'),
      body: ListView(
        padding: AppLayout.pageInsets(context),
        children: [
          StudeeGlass(
            borderRadius: 16,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  'DeepSeek',
                  trailing: credsAsync.isLoading
                      ? null
                      : Text(
                          hasKey ? 'Đã lưu $maskedDeepSeek' : 'Chưa lưu',
                          style: TextStyle(
                            color: hasKey
                                ? AppColors.success
                                : AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _deepSeekController,
                  obscureText: _obscureDeepSeek,
                  decoration: InputDecoration(
                    labelText: 'Khóa API',
                    hintText: 'sk-...',
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscureDeepSeek = !_obscureDeepSeek,
                      ),
                      icon: Icon(
                        _obscureDeepSeek
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionRow(
                  busy: _busy,
                  onSave: _saveDeepSeek,
                  onTest: _testDeepSeek,
                  onDelete: _deleteDeepSeek,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StudeeGlass(
            borderRadius: 16,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  'Mathpix OCR',
                  trailing: credsAsync.isLoading
                      ? null
                      : Text(
                          hasMathpix
                              ? 'Đã lưu $maskedMathpixId'
                              : 'Chưa lưu',
                          style: TextStyle(
                            color: hasMathpix
                                ? AppColors.success
                                : AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _mathpixAppIdController,
                  decoration: const InputDecoration(labelText: 'App ID'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _mathpixAppKeyController,
                  obscureText: _obscureMathpixKey,
                  decoration: InputDecoration(
                    labelText: 'App Key',
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscureMathpixKey = !_obscureMathpixKey,
                      ),
                      icon: Icon(
                        _obscureMathpixKey
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: const Text(
                      'Nâng cao',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    children: [
                      TextField(
                        controller: _mathpixBaseUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Máy chủ tuỳ chọn',
                          hintText: 'https://…',
                        ),
                      ),
                    ],
                  ),
                ),
                _ActionRow(
                  busy: _busy,
                  onSave: _saveMathpix,
                  onTest: _testMathpix,
                  onDelete: _deleteMathpix,
                ),
              ],
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_status != null) ...[
            const SizedBox(height: 12),
            StudeeGlass(
              borderRadius: 12,
              padding: const EdgeInsets.all(12),
              child: Text(
                _status!,
                style: TextStyle(color: _statusColor, height: 1.35),
              ),
            ),
          ],
          if (Platform.isMacOS) ...[
            const SizedBox(height: 12),
            StudeeGlass(
              borderRadius: 16,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StudeeSectionLabel('Hệ thống'),
                  const SizedBox(height: 10),
                  const _SectionTitle('Ghi màn hình'),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _busy ? null : _resetScreenCapture,
                    child: const Text('Đặt lại quyền'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          StudeeGlass(
            borderRadius: 16,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StudeeSectionLabel('Phím tắt'),
                const SizedBox(height: 10),
                Text(
                  Platform.isMacOS
                      ? '⌘↵ giải câu hỏi'
                      : 'Ctrl+Enter giải câu hỏi',
                  style: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.busy,
    required this.onSave,
    required this.onTest,
    required this.onDelete,
  });

  final bool busy;
  final VoidCallback onSave;
  final VoidCallback onTest;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton(
          onPressed: busy ? null : onSave,
          child: const Text('Lưu'),
        ),
        OutlinedButton(
          onPressed: busy ? null : onTest,
          child: const Text('Kiểm tra'),
        ),
        TextButton(
          onPressed: busy ? null : onDelete,
          child: const Text(
            'Xóa',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}
