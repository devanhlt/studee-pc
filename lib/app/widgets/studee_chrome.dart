import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:studee_pc/app/theme/app_colors.dart';

/// Soft amber atmosphere used behind every primary Studee screen.
class StudeeAtmosphere extends StatelessWidget {
  const StudeeAtmosphere({super.key, this.intensity = 1});

  /// 0–1 scale for glow strength (detail screens can use slightly less).
  final double intensity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _StudeeAtmospherePainter(intensity: intensity.clamp(0.0, 1.0)),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _StudeeAtmospherePainter extends CustomPainter {
  _StudeeAtmospherePainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, base);

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.75, -0.95),
        radius: 1.15,
        colors: [
          AppColors.accent.withValues(alpha: 0.22 * intensity),
          AppColors.accent.withValues(alpha: 0.06 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1A1612).withValues(alpha: 0.55 * intensity),
          AppColors.background.withValues(alpha: 0.15 * intensity),
          AppColors.background,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.accent.withValues(alpha: 0.12 * intensity);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width + 20, -30), radius: 140),
      0.6,
      math.pi,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width + 20, -30), radius: 176),
      0.75,
      math.pi * 0.85,
      false,
      arcPaint..color = AppColors.primaryText.withValues(alpha: 0.05 * intensity),
    );

    final linePaint = Paint()
      ..color = AppColors.primaryText.withValues(alpha: 0.035 * intensity)
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final y = 90.0 + i * 58;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + i * 2.5), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StudeeAtmospherePainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

/// Frosted glass panel — use for headers, sticky bars, and primary cards.
class StudeeGlass extends StatelessWidget {
  const StudeeGlass({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.blur = 18,
    this.opacity = 0.58,
    this.border = true,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  final bool border;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: AppColors.elevated.withValues(alpha: opacity),
            border: border
                ? Border.all(
                    color: AppColors.border.withValues(alpha: 0.72),
                  )
                : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

/// Page shell: atmosphere + optional glass top bar + body (+ optional bottom).
class StudeePageScaffold extends StatelessWidget {
  const StudeePageScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.bottomBar,
    this.floatingActionButton,
    this.atmosphereIntensity = 0.85,
  });

  final Widget body;
  final Widget? topBar;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final double atmosphereIntensity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: Stack(
        fit: StackFit.expand,
        children: [
          StudeeAtmosphere(intensity: atmosphereIntensity),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (topBar != null) topBar!,
              Expanded(child: body),
              if (bottomBar != null) bottomBar!,
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact glass app bar used on detail / settings / import screens.
class StudeeGlassAppBar extends StatelessWidget {
  const StudeeGlassAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, top + 8, 10, 8),
      child: StudeeGlass(
        borderRadius: 14,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: SizedBox(
          height: subtitle == null ? 48 : 56,
          child: Row(
            children: [
              if (leading != null)
                leading!
              else
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.primaryText,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// Accent tick + section label (same as home “Môn học của bạn”).
class StudeeSectionLabel extends StatelessWidget {
  const StudeeSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryText,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Translucent content card (lighter glass — no blur for list performance).
class StudeeCard extends StatelessWidget {
  const StudeeCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.accentColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    return Material(
      color: AppColors.elevated.withValues(alpha: 0.88),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.85)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: accent == null
              ? const BoxDecoration()
              : BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: accent.withValues(alpha: 0.9),
                      width: 4,
                    ),
                  ),
                ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Sticky bottom glass action strip.
class StudeeGlassFooter extends StatelessWidget {
  const StudeeGlassFooter({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 8 + insets.bottom * 0.35),
      child: StudeeGlass(
        borderRadius: 14,
        padding: padding ??
            const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: child,
      ),
    );
  }
}
