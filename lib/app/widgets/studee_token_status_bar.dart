import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_typography.dart';
import 'package:studee_pc/features/settings/application/activation_request_config.dart';
import 'package:studee_pc/features/settings/application/entitlement_provider.dart';

/// Edge-to-edge token quota bar at the top of every [StudeePageScaffold].
class StudeeTokenStatusBar extends ConsumerWidget {
  const StudeeTokenStatusBar({super.key});

  static const double _height = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(entitlementProvider);
    final info = async.asData?.value;

    late final double progress;
    late final Color barColor;
    late final String label;
    late final String semanticsLabel;

    if (async.isLoading && info == null) {
      progress = 0;
      barColor = AppColors.borderStrong;
      label = 'Đang tải…';
      semanticsLabel = 'Đang tải token';
    } else if (info == null || info.maxSolves <= 0) {
      progress = 0;
      barColor = AppColors.borderStrong;
      label = 'Chưa có mã';
      semanticsLabel = 'Chưa có mã kích hoạt';
    } else if (info.status == 'expired' || info.status == 'revoked') {
      progress = 0;
      barColor = AppColors.error;
      label = 'Hết hạn';
      semanticsLabel = 'Mã hết hạn';
    } else {
      final remaining = info.remaining.clamp(0, info.maxSolves).toInt();
      progress = (remaining / info.maxSolves).clamp(0.0, 1.0);
      barColor = progress >= 0.3
          ? AppColors.accent
          : progress >= 0.1
              ? AppColors.warning
              : AppColors.error;
      label =
          '${ActivationRequestConfig.formatTokens(remaining)} / ${ActivationRequestConfig.formatTokens(info.maxSolves)}';
      semanticsLabel = 'Token còn lại $remaining trên ${info.maxSolves}';
    }

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final path = GoRouterState.of(context).uri.path;
          if (path == '/settings' || path.startsWith('/settings/')) {
            return;
          }
          context.push('/settings');
        },
        child: SizedBox(
          height: _height,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.border.withValues(alpha: 0.55),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      heightFactor: 1,
                      child: ColoredBox(color: barColor),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontFamilyFallback: AppTypography.fontFamilyFallback,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    letterSpacing: 0.2,
                    color: Color(0xFFFFFFFF),
                    shadows: [
                      Shadow(
                        color: Color(0xE6000000),
                        blurRadius: 2,
                        offset: Offset(0, 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
