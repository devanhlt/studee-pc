import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/theme/app_motion.dart';

/// Soft aurora atmosphere used behind every primary Studee screen.
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

    // Violet aurora — top-left.
    final violetGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.85, -0.95),
        radius: 1.05,
        colors: [
          AppColors.violet.withValues(alpha: 0.18 * intensity),
          AppColors.violet.withValues(alpha: 0.05 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, violetGlow);

    // Cyan aurora — bottom-right.
    final cyanGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.95, 1.05),
        radius: 1.0,
        colors: [
          AppColors.cyan.withValues(alpha: 0.14 * intensity),
          AppColors.cyan.withValues(alpha: 0.04 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, cyanGlow);

    // Soft vertical wash.
    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.surface.withValues(alpha: 0.45 * intensity),
          AppColors.background.withValues(alpha: 0.12 * intensity),
          AppColors.background,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);

    // Faint mesh grid for an engineered feel.
    final mesh = Paint()
      ..color = AppColors.primaryText.withValues(alpha: 0.028 * intensity)
      ..strokeWidth = 1;
    const step = 42.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), mesh);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), mesh);
    }

    // Subtle arc accent near the top-right.
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.accent.withValues(alpha: 0.1 * intensity);
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
      arcPaint
        ..color = AppColors.cyan.withValues(alpha: 0.06 * intensity),
    );
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
    this.borderRadius = AppLayout.radiusCard,
    this.padding,
    this.blur = 18,
    this.opacity = 0.58,
    this.border = true,
    this.clipBehavior = Clip.antiAlias,
    this.gradientBorder = false,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;
  final bool border;
  final Clip clipBehavior;

  /// Draw a violet→cyan hairline around the panel.
  final bool gradientBorder;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final panel = ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: AppColors.elevated.withValues(alpha: opacity),
            border: border && !gradientBorder
                ? Border.all(
                    color: AppColors.border.withValues(alpha: 0.72),
                  )
                : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.015),
              ],
            ),
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );

    if (!gradientBorder) return panel;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: AppColors.intelligence,
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.1),
        child: panel,
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
    this.atmosphereIntensity = AppLayout.atmospherePage,
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
              ?topBar,
              Expanded(child: body),
              ?bottomBar,
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
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: SizedBox(
          height: subtitle == null ? 52 : 60,
          child: Row(
            children: [
              if (leading != null)
                leading!
              else
                IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(AppIcons.back),
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
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
          height: 16,
          decoration: BoxDecoration(
            gradient: AppColors.intelligence,
            borderRadius: AppLayout.xsBorder,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 0.1,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Translucent content card with desktop hover lift.
class StudeeCard extends StatefulWidget {
  const StudeeCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.accentColor,
    this.gradientBorder = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final bool gradientBorder;

  @override
  State<StudeeCard> createState() => _StudeeCardState();
}

class _StudeeCardState extends State<StudeeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final duration = AppMotion.duration(context, AppMotion.fast);
    final lift = _hovered && widget.onTap != null ? AppMotion.hoverLift : 0.0;

    Widget card = AnimatedContainer(
      duration: duration,
      curve: AppMotion.easeOut,
      transform: Matrix4.translationValues(0, -lift, 0),
      decoration: BoxDecoration(
        borderRadius: AppLayout.cardBorder,
        boxShadow: _hovered && widget.onTap != null
            ? [
                BoxShadow(
                  color: (accent ?? AppColors.accent)
                      .withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: AppColors.elevated.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: AppLayout.cardBorder,
          side: BorderSide(
            color: _hovered
                ? AppColors.borderStrong.withValues(alpha: 0.95)
                : AppColors.border.withValues(alpha: 0.85),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppLayout.cardBorder,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
                left: accent == null
                    ? BorderSide.none
                    : BorderSide(
                        color: accent.withValues(alpha: 0.9),
                        width: 4,
                      ),
              ),
            ),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );

    if (widget.gradientBorder) {
      card = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppLayout.cardBorder,
          gradient: AppColors.intelligence,
        ),
        child: Padding(
          padding: const EdgeInsets.all(1.1),
          child: card,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: card,
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
        padding: padding ?? const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: child,
      ),
    );
  }
}
