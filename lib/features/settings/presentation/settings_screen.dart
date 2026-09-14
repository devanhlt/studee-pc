import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/dependency_setup.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';
import 'package:studee_pc/domain/repositories/stored_api_credentials.dart';
import 'package:studee_pc/features/settings/application/activation_request_config.dart';
import 'package:studee_pc/features/settings/application/quota_revision.dart';
import 'package:studee_pc/features/settings/application/settings_service.dart';

final settingsCredentialsProvider =
    FutureProvider.autoDispose<StoredApiCredentials>((ref) {
  return ref.watch(settingsServiceProvider).loadCredentials();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _codeController = TextEditingController();
  bool _obscureCode = true;
  bool _busy = false;
  String? _status;
  EntitlementInfo? _entitlement;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  SettingsService get _service => ref.read(settingsServiceProvider);

  void _refreshCredentials() {
    ref.invalidate(settingsCredentialsProvider);
    ref.read(quotaRevisionProvider.notifier).state++;
  }

  Color get _statusColor {
    final s = _status ?? '';
    if (s.contains('thành công') ||
        s.contains('còn') ||
        (s.startsWith('Đã') && !s.contains('Thoát') && !s.contains('Đặt lại'))) {
      return AppColors.success;
    }
    if (s.contains('Thoát') || s.contains('Đặt lại')) {
      return AppColors.secondaryText;
    }
    return AppColors.error;
  }

  Future<void> _saveCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() => _status = 'Hãy dán mã kích hoạt vào trước.');
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
      _entitlement = null;
    });
    final result = await _service.saveActivationCode(_codeController.text);
    setState(() => _busy = false);
    result.when(
      success: (_) {
        _codeController.clear();
        _refreshCredentials();
        setState(() => _status = 'Đã lưu mã kích hoạt.');
      },
      failure: (f) => setState(() => _status = f.userMessage),
    );
  }

  Future<void> _deleteCode() async {
    setState(() {
      _busy = true;
      _status = null;
      _entitlement = null;
    });
    final result = await _service.deleteActivationCode();
    setState(() => _busy = false);
    result.when(
      success: (_) {
        _refreshCredentials();
        setState(() => _status = 'Đã xóa mã kích hoạt khỏi máy.');
      },
      failure: (f) => setState(() => _status = f.userMessage),
    );
  }

  Future<void> _testCode() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final result = await _service.fetchEntitlement();
    setState(() => _busy = false);
    result.when(
      success: (info) {
        setState(() {
          _entitlement = info;
          _status = null;
        });
      },
      failure: (f) => setState(() {
        _entitlement = null;
        _status = f.userMessage;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credsAsync = ref.watch(settingsCredentialsProvider);

    var hasCode = false;
    String? maskedCode;
    credsAsync.whenData((c) {
      hasCode = c.hasActivationCode;
      final code = c.activationCode;
      if (code != null && code.isNotEmpty) {
        maskedCode = code.length <= 8
            ? '••••••••'
            : '••••${code.substring(code.length - 4)}';
      }
    });

    return StudeePageScaffold(
      atmosphereIntensity: AppLayout.atmospherePage,
      topBar: const StudeeGlassAppBar(title: 'Cài đặt'),
      body: ListView(
        padding: AppLayout.pageInsets(context),
        children: [
          StudeeGlass(
            padding: const EdgeInsets.all(AppLayout.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  'Nhập mã kích hoạt',
                  trailing: credsAsync.isLoading
                      ? null
                      : Text(
                          hasCode ? 'Đã lưu $maskedCode' : 'Chưa lưu',
                          style: TextStyle(
                            color: hasCode
                                ? AppColors.success
                                : AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dán mã bạn đã có để sử dụng.',
                  style: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.95),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  obscureText: _obscureCode,
                  decoration: InputDecoration(
                    labelText: 'Mã kích hoạt',
                    hintText: 'STU-XXXX-XXXX-XXXX',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscureCode = !_obscureCode),
                      icon: Icon(
                        _obscureCode
                            ? AppIcons.visibility
                            : AppIcons.visibilityOff,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ActionRow(
                  busy: _busy,
                  onSave: _saveCode,
                  onTest: _testCode,
                  onDelete: _deleteCode,
                ),
                if (_entitlement != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Gói ${_entitlement!.plan} · '
                    '${ActivationRequestConfig.formatTokens(_entitlement!.solvesUsed)}/${ActivationRequestConfig.formatTokens(_entitlement!.maxSolves)} token đã dùng · '
                    'trạng thái ${_entitlement!.status}',
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _OrDivider(),
          const SizedBox(height: 16),
          StudeeGlass(
            padding: const EdgeInsets.all(AppLayout.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionTitle('Yêu cầu mã'),
                const SizedBox(height: 8),
                Text(
                  'Chưa có mã? Chọn gói và thanh toán để nhận mã kích hoạt ngay.',
                  style: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.95),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/settings/request-code'),
                  icon: const Icon(AppIcons.qrCode),
                  label: const Text('Yêu cầu mã'),
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
              borderRadius: AppLayout.radiusControl,
              padding: const EdgeInsets.all(12),
              child: Text(
                _status!,
                style: TextStyle(color: _statusColor, height: 1.35),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Hoặc',
            style: TextStyle(
              color: AppColors.secondaryText.withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
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
    return Row(
      children: [
        FilledButton(
          onPressed: busy ? null : onSave,
          child: const Text('Lưu'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: busy ? null : onTest,
          child: const Text('Kiểm tra'),
        ),
        const Spacer(),
        TextButton(
          onPressed: busy ? null : onDelete,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Xóa'),
        ),
      ],
    );
  }
}
