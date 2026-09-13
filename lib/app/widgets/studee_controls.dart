import 'package:flutter/material.dart';
import 'package:studee_pc/app/theme/app_colors.dart';
import 'package:studee_pc/app/theme/app_icons.dart';
import 'package:studee_pc/app/theme/app_layout.dart';
import 'package:studee_pc/app/theme/app_motion.dart';
import 'package:studee_pc/app/theme/app_typography.dart';
import 'package:studee_pc/app/widgets/studee_chrome.dart';

/// Animated segmented control with a sliding intelligence-gradient pill.
class StudeeSegmentedControl<T> extends StatelessWidget {
  const StudeeSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final List<StudeeSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selectedIndex =
        segments.indexWhere((s) => s.value == selected).clamp(0, segments.length - 1);
    final duration = AppMotion.duration(context, AppMotion.base);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: IgnorePointer(
        ignoring: !enabled,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final count = segments.length;
            final segmentWidth = constraints.maxWidth / count;
            return Container(
              height: count >= 4 ? 42 : 40,
              decoration: BoxDecoration(
                color: AppColors.elevated.withValues(alpha: 0.9),
                borderRadius: AppLayout.controlBorder,
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: duration,
                    curve: AppMotion.easeOut,
                    left: selectedIndex * segmentWidth + 3,
                    top: 3,
                    bottom: 3,
                    width: segmentWidth - 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppLayout.radiusControl - 2,
                        ),
                        gradient: AppColors.intelligence,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final segment in segments)
                        Expanded(
                          child: InkWell(
                            borderRadius: AppLayout.controlBorder,
                            onTap: () => onChanged(segment.value),
                            child: SizedBox.expand(
                              child: Center(
                                child: count >= 4 || segment.icon == null
                                    ? Text(
                                        segment.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                        textAlign: TextAlign.center,
                                        textHeightBehavior:
                                            const TextHeightBehavior(
                                          applyHeightToFirstAscent: false,
                                          applyHeightToLastDescent: false,
                                        ),
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: count >= 4 ? 13 : 14,
                                          fontWeight: FontWeight.w600,
                                          height: 1.0,
                                          color: segment.value == selected
                                              ? AppColors.onAccent
                                              : AppColors.secondaryText,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            segment.icon,
                                            size: 16,
                                            color: segment.value == selected
                                                ? AppColors.onAccent
                                                : AppColors.secondaryText,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            segment.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                            textHeightBehavior:
                                                const TextHeightBehavior(
                                              applyHeightToFirstAscent: false,
                                              applyHeightToLastDescent: false,
                                            ),
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTypography.fontFamily,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              height: 1.0,
                                              color: segment.value == selected
                                                  ? AppColors.onAccent
                                                  : AppColors.secondaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class StudeeSegment<T> {
  const StudeeSegment({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Primary action button filled with the intelligence gradient.
class StudeeGradientButton extends StatefulWidget {
  const StudeeGradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.expanded = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool expanded;

  @override
  State<StudeeGradientButton> createState() => _StudeeGradientButtonState();
}

class _StudeeGradientButtonState extends State<StudeeGradientButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.onAccent,
      ),
    );
    final child = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: AppColors.onAccent),
          const SizedBox(width: 6),
        ],
        if (widget.expanded) Flexible(child: label) else label,
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedOpacity(
        duration: AppMotion.duration(context, AppMotion.fast),
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: AppLayout.controlBorder,
            child: AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.fast),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: AppLayout.controlBorder,
                gradient: enabled
                    ? AppColors.intelligence
                    : null,
                color: enabled ? null : AppColors.border,
                boxShadow: enabled && _hovered
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact stat / tag pill.
class StudeePill extends StatelessWidget {
  const StudeePill({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.secondaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevated.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppLayout.radiusPill),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c,
              fontFeatures: AppTypography.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// Confidence meter with 3 segments (low / medium / high).
class StudeeConfidenceMeter extends StatelessWidget {
  const StudeeConfidenceMeter({
    super.key,
    required this.level,
    required this.label,
  });

  /// 0 = conflict/low, 1 = medium, 2 = high. Values above 2 clamp to high.
  final int level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (level.clamp(0, 2)) {
      2 => AppColors.success,
      1 => AppColors.accent,
      _ => AppColors.error,
    };
    final filled = level.clamp(0, 2) + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevated.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppLayout.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(3, (i) {
              final on = i < filled;
              return Container(
                width: 16,
                height: 6,
                margin: EdgeInsets.only(right: i < 2 ? 3 : 0),
                decoration: BoxDecoration(
                  borderRadius: AppLayout.xsBorder,
                  color: on
                      ? color
                      : AppColors.border.withValues(alpha: 0.7),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three-dot typing indicator for AI thinking.
class StudeeTypingIndicator extends StatefulWidget {
  const StudeeTypingIndicator({super.key});

  @override
  State<StudeeTypingIndicator> createState() => _StudeeTypingIndicatorState();
}

class _StudeeTypingIndicatorState extends State<StudeeTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) {
      return _dots(const [1.0, 1.0, 1.0]);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return _dots([
          _pulse(t),
          _pulse(t - 0.2),
          _pulse(t - 0.4),
        ]);
      },
    );
  }

  double _pulse(double t) {
    final x = ((t % 1) + 1) % 1;
    return 0.35 + 0.65 * (1 - (2 * x - 1).abs());
  }

  Widget _dots(List<double> alphas) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Opacity(
            opacity: alphas[i].clamp(0.25, 1.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.intelligence,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Animated gradient progress bar with optional stage label.
class StudeeGradientProgress extends StatelessWidget {
  const StudeeGradientProgress({
    super.key,
    this.label,
    this.value,
  });

  final String? label;

  /// Null = indeterminate shimmer style.
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppLayout.radiusPill),
          child: SizedBox(
            height: 4,
            child: value == null
                ? const _IndeterminateGradientBar()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: AppColors.border),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value!.clamp(0.0, 1.0),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.intelligence,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _IndeterminateGradientBar extends StatefulWidget {
  const _IndeterminateGradientBar();

  @override
  State<_IndeterminateGradientBar> createState() =>
      _IndeterminateGradientBarState();
}

class _IndeterminateGradientBarState extends State<_IndeterminateGradientBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.border,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Align(
            alignment: Alignment(-1.2 + t * 2.4, 0),
            child: FractionallySizedBox(
              widthFactor: 0.35,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.violet.withValues(alpha: 0),
                      AppColors.accent,
                      AppColors.cyan.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Composer field with focus glow ring.
class StudeeFocusComposer extends StatefulWidget {
  const StudeeFocusComposer({
    super.key,
    required this.child,
    this.borderRadius = AppLayout.radiusCard,
  });

  final Widget child;
  final double borderRadius;

  @override
  State<StudeeFocusComposer> createState() => _StudeeFocusComposerState();
}

class _StudeeFocusComposerState extends State<StudeeFocusComposer> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: AppMotion.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.22),
                    blurRadius: 16,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Shared empty / error state with icon, title, message, and optional action.
class StudeeStatusState extends StatelessWidget {
  const StudeeStatusState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppLayout.gapXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppIcons.sizeEmptyState,
              color: AppColors.accent.withValues(alpha: 0.85),
            ),
            const SizedBox(height: AppLayout.gapMd),
            Text(
              title,
              style: theme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppLayout.gapSm),
            Text(
              message,
              style: theme.bodyMedium?.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppLayout.gapLg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder card list used while content loads.
class StudeeSkeletonList extends StatelessWidget {
  const StudeeSkeletonList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppLayout.pagePadding),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppLayout.gapSm),
      itemBuilder: (_, _) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return StudeeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(widthFactor: 0.55, height: 14),
          const SizedBox(height: AppLayout.gapSm),
          _bar(widthFactor: 1, height: 10),
          const SizedBox(height: AppLayout.gapXs),
          _bar(widthFactor: 0.82, height: 10),
          const SizedBox(height: AppLayout.gapSm),
          _bar(widthFactor: 0.35, height: 10),
        ],
      ),
    );
  }

  Widget _bar({required double widthFactor, required double height}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.55),
          borderRadius: AppLayout.xsBorder,
        ),
      ),
    );
  }
}
