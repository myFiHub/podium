import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/widgets/ui/aurora.dart';

export 'package:podium/widgets/ui/aurora.dart';

/// Podium design kit: the look of the outpost call page, shared by every
/// screen. Prefer these over hand-rolled containers so screens stay
/// consistent.

class AppColors {
  AppColors._();

  static AppPalette get _p => AppPalette.current;

  static Color get success => _p.success;
  static Color get danger => _p.danger;
  static Color get accent => _p.warning;
  static Color get live => _p.danger;
  static Color get primary => _p.accent;
  static Color get violet => _p.violet;
  static Color get magenta => _p.magenta;

  /// Text/icons on [primary] fills.
  static Color get onPrimary => _p.onAccent;

  static Color get surface => _p.surface;

  /// Slightly lifted surface for sheets, dialogs and popovers.
  static Color get surfaceRaised => _p.surfaceRaised;
  static Color get border => _p.border;
  static Color get textMuted => _p.textMuted;
  static Color get textFaint => _p.textFaint;

  /// Translucent card fill that lets the page gradient show through.
  static Color get surfaceGlass => _p.surface.withAlpha(200);

  /// Fill for inputs, chips and icon buttons sitting on a surface.
  static Color get fill => _p.text.withAlpha(12);

  /// Legible text/icon color for content drawn on a solid [background].
  static Color onColor(Color background) {
    final isLightBackground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.light;
    if (_p.isLight) return isLightBackground ? _p.text : _p.surfaceRaised;
    return isLightBackground ? _p.surface : _p.text;
  }
}

class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

class AppText {
  AppText._();

  static TextStyle get pageTitle => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: ColorName.white,
      );
  static TextStyle get title => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ColorName.white,
      );
  static TextStyle get cardTitle => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: ColorName.white,
      );
  static TextStyle get body =>
      TextStyle(fontSize: 14, color: ColorName.white, height: 1.4);
  static TextStyle get muted =>
      TextStyle(fontSize: 13, color: ColorName.greyText);
  static TextStyle get caption =>
      TextStyle(fontSize: 12, color: ColorName.greyText);
  static TextStyle get label => TextStyle(
        fontSize: 12,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: ColorName.greyText,
      );
}

/// Rounded translucent card with a hairline border.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  /// Hairline gradient; ignored when [borderColor] is set.
  final Gradient? borderGradient;
  final double radius;
  final Gradient? gradient;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderGradient,
    this.radius = AppRadius.lg,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // The border is painted in the foreground so toggling it never shifts layout.
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: AppPressScale(
        enabled: onTap != null,
        scale: 0.985,
        child: CustomPaint(
          foregroundPainter: GradientBorderPainter(
            radius: radius,
            gradient: borderColor == null
                ? borderGradient
                : LinearGradient(colors: [borderColor!, borderColor!]),
          ),
          child: Material(
            color: Colors.transparent,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: ShapeDecoration(
                shape: shape,
                color:
                    gradient == null ? (color ?? AppColors.surfaceGlass) : null,
                gradient: gradient,
              ),
              child: InkWell(
                onTap: onTap,
                splashColor: AppColors.violet.withAlpha(30),
                highlightColor: AppColors.primary.withAlpha(10),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section heading for settings and form pages, aligned with [AppCard] edges.
class AppSectionLabel extends StatelessWidget {
  final String title;
  const AppSectionLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: title,
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    );
  }
}

/// Hairline between rows inside an [AppCard].
class AppRowDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  const AppRowDivider({super.key, this.indent = 16, this.endIndent = 16});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: endIndent,
      color: AppColors.border,
    );
  }
}

/// Icon on a soft tinted square (or circle) used as a row's leading badge.
class AppIconTile extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final bool circle;
  final bool bordered;
  const AppIconTile({
    super.key,
    required this.icon,
    this.color,
    this.size = 38,
    this.circle = false,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withAlpha(30),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(AppRadius.sm),
        border: bordered ? Border.all(color: tint.withAlpha(50)) : null,
      ),
      child: Icon(icon, size: size * 0.5, color: tint),
    );
  }
}

/// Tappable settings row: icon tile, title, optional subtitle and trailing
/// widget (a chevron when tappable and no trailing is given). [dense] is the
/// tighter variant used inside forms.
class AppSettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dimmed;
  final bool dense;
  const AppSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dimmed = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: 16, vertical: dense ? 10 : 14),
        child: Row(
          children: [
            AppIconTile(
              icon: icon,
              color: dimmed ? AppColors.textMuted : iconColor,
              bordered: !dense,
            ),
            SizedBox(width: dense ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(
                      fontSize: dense ? 14 : null,
                      fontWeight: FontWeight.w600,
                      color: dimmed ? AppColors.textMuted : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                (onTap != null
                    ? Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

/// Small uppercase label above a group of content, with optional count and
/// action.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  const AppSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.actionLabel,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 8, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text('$count', style: AppText.caption),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primary,
              ),
              child: Text(
                actionLabel ?? 'See all',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Large page title with an optional subtitle, back button and actions.
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final EdgeInsetsGeometry padding;
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = false,
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 12, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (showBack) ...[
            AppIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: showBack
                      ? AppText.title.copyWith(fontSize: 20)
                      : AppText.pageTitle,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  AppRollingText(subtitle!, style: AppText.muted),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Circular translucent icon button.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;
  final Color? background;
  final double size;
  const AppIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.color,
    this.background,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: size * 0.5),
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        backgroundColor: background ?? AppColors.fill,
        foregroundColor: color ?? ColorName.white,
        side: BorderSide(color: AppColors.border),
      ),
    );
  }
}

/// Compact circular refresh button. Spins with a gradient ring while
/// [loading], finishes its turn when loading ends and briefly shows a check.
class AppRefreshButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onTap;
  final String tooltip;
  final double size;
  const AppRefreshButton({
    super.key,
    required this.loading,
    required this.onTap,
    this.tooltip = 'Refresh',
    this.size = 36,
  });

  @override
  State<AppRefreshButton> createState() => _AppRefreshButtonState();
}

class _AppRefreshButtonState extends State<AppRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  Timer? _doneTimer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    if (widget.loading) _spin.repeat();
  }

  @override
  void didUpdateWidget(AppRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loading == widget.loading) return;
    if (widget.loading) {
      _doneTimer?.cancel();
      _done = false;
      _spin.repeat();
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final remaining = 1 - _spin.value;
    await _spin.animateTo(
      1,
      duration: Duration(milliseconds: 200 + (500 * remaining).round()),
      curve: Curves.easeOutCubic,
    );
    if (!mounted || widget.loading) return;
    _spin.value = 0;
    setState(() => _done = true);
    _doneTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _done = false);
    });
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.loading;
    final still = reduceMotion(context);
    final turns = still ? const AlwaysStoppedAnimation(0.0) : _spin;
    final iconSize = widget.size * 0.5;
    const duration = Duration(milliseconds: 250);
    return Tooltip(
      message: widget.tooltip,
      child: AppPressScale(
        enabled: !active,
        scale: 0.9,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary.withAlpha(20) : AppColors.fill,
            border: Border.all(
              color: active
                  ? Colors.transparent
                  : _done
                      ? AppColors.success.withAlpha(110)
                      : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withAlpha(active ? 70 : 0),
                blurRadius: 14,
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: active ? null : widget.onTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: AnimatedOpacity(
                      opacity: active ? 1 : 0,
                      duration: duration,
                      child: RotationTransition(
                        turns: turns,
                        child: const CustomPaint(painter: _RefreshArcPainter()),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: duration,
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: _done
                        ? Icon(
                            Icons.check_rounded,
                            key: const ValueKey('done'),
                            size: iconSize,
                            color: AppColors.success,
                          )
                        : RotationTransition(
                            key: const ValueKey('idle'),
                            turns: turns,
                            child: TweenAnimationBuilder<Color?>(
                              tween: ColorTween(
                                end: active
                                    ? AppColors.primary
                                    : ColorName.white,
                              ),
                              duration: duration,
                              builder: (context, color, _) => Icon(
                                Icons.autorenew_rounded,
                                size: iconSize,
                                color: color,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RefreshArcPainter extends CustomPainter {
  const _RefreshArcPainter();

  static const _stroke = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          AppColors.primary.withAlpha(0),
          AppColors.primary,
          AppColors.violet,
        ],
        stops: const [0, 0.45, 0.7],
      ).createShader(rect);
    canvas.drawArc(rect, 0, math.pi * 1.4, false, paint);
  }

  @override
  bool shouldRepaint(_RefreshArcPainter oldDelegate) => false;
}

/// Full-width primary action with a loading state.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;
  final Color? foreground;
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppColors.onColor(color ?? AppColors.primary);
    final useGradient = color == null && onPressed != null;
    return AppGradientShell(
      enabled: useGradient,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: _button(fg, useGradient),
    );
  }

  Widget _button(Color fg, bool useGradient) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor:
            useGradient ? Colors.transparent : (color ?? AppColors.primary),
        foregroundColor: fg,
        disabledBackgroundColor: loading
            ? (useGradient
                ? Colors.transparent
                : (color ?? AppColors.primary).withAlpha(150))
            : ColorName.white.withAlpha(18),
        disabledForegroundColor: loading ? fg : ColorName.white.withAlpha(90),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
    );
  }
}

/// Paints the brand gradient and a soft glow behind a transparent button.
class AppGradientShell extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final BorderRadius borderRadius;
  final Gradient? gradient;
  Gradient get _gradient => gradient ?? AppGradients.primary;

  const AppGradientShell({
    super.key,
    required this.child,
    required this.borderRadius,
    this.enabled = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return AppPressScale(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withAlpha(70),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.primary.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Full-width secondary (outlined) action.
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? ColorName.white;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: fg,
        backgroundColor: AppColors.fill,
        side: BorderSide(
          color: color == null ? AppColors.border : fg.withAlpha(120),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// Small rounded status/label chip.
class AppPill extends StatelessWidget {
  final String label;
  final Color? color;
  Color get _color => color ?? ColorName.greyText;

  final IconData? icon;
  final bool filled;
  const AppPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? _color : _color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withAlpha(filled ? 255 : 70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 13, color: filled ? AppColors.onColor(_color) : _color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: filled ? AppColors.onColor(_color) : _color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered illustration-style placeholder for empty lists and errors.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 32,
        vertical: compact ? 16 : 40,
      ),
      child: AppEntrance(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBreathing(
              period: const Duration(milliseconds: 2800),
              builder: (context, v) => Transform.translate(
                offset: Offset(0, 3 - 6 * v),
                child: _badge(v),
              ),
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(title, textAlign: TextAlign.center, style: AppText.cardTitle),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppText.muted.copyWith(height: 1.4),
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(actionLabel ?? 'Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(double glow) {
    return Container(
      width: compact ? 52 : 72,
      height: compact ? 52 : 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withAlpha(46),
            AppColors.violet.withAlpha(46),
            AppColors.magenta.withAlpha(36),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.violet.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withAlpha(36 + (36 * glow).round()),
            blurRadius: 20 + 10 * glow,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: compact ? 24 : 32,
        color: AppColors.primary,
      ),
    );
  }
}

/// Bottom sheet chrome: grabber, optional title row (with leading [icon] and
/// [subtitle]), a soft brand glow along the top edge and safe-area padding.
class AppSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final EdgeInsets padding;
  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 20),
  });

  static const double _radius = 28;

  /// Max height for a sheet opened with [Get.bottomSheet], which already lifts
  /// its content above the keyboard.
  static double maxHeight(BuildContext context, double fraction) {
    final media = MediaQuery.of(context);
    final available =
        media.size.height - media.viewInsets.bottom - media.padding.top - 24;
    return (media.size.height * fraction).clamp(0.0, available);
  }

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(_radius)),
    );
    return CustomPaint(
      foregroundPainter: const _SheetEdgePainter(radius: _radius),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          color: AppColors.surfaceRaised,
          shadows: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const ShapeBorderClipper(shape: shape),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 140,
                child: IgnorePointer(child: _SheetGlow()),
              ),
              SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ColorName.white.withAlpha(46),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (title != null) _header(),
                    Flexible(child: Padding(padding: padding, child: child)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 16),
      child: Row(
        children: [
          if (icon != null) ...[
            AppIconTile(
              icon: icon!,
              color: iconColor,
              size: 40,
              bordered: true,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Faint cyan/violet light pooling under the sheet's top edge.
class _SheetGlow extends StatelessWidget {
  const _SheetGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -1.4),
          radius: 1.6,
          colors: [
            AppColors.primary.withAlpha(26),
            AppColors.violet.withAlpha(14),
            AppColors.violet.withAlpha(0),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
    );
  }
}

/// Hairline along the sheet's rounded top edge that fades out down the sides.
class _SheetEdgePainter extends CustomPainter {
  final double radius;
  const _SheetEdgePainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0.5, radius * 2.5)
      ..lineTo(0.5, radius)
      ..arcToPoint(Offset(radius, 0.5), radius: Radius.circular(radius - 0.5))
      ..lineTo(size.width - radius, 0.5)
      ..arcToPoint(
        Offset(size.width - 0.5, radius),
        radius: Radius.circular(radius - 0.5),
      )
      ..lineTo(size.width - 0.5, radius * 2.5);
    final bounds = Rect.fromLTWH(0, 0, size.width, radius * 2.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [ColorName.white.withAlpha(36), ColorName.white.withAlpha(0)],
      ).createShader(bounds);
    canvas.drawPath(path, paint);
    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withAlpha(0),
          AppColors.primary.withAlpha(110),
          AppColors.violet.withAlpha(90),
          AppColors.violet.withAlpha(0),
        ],
        stops: const [0.08, 0.35, 0.65, 0.92],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1));
    canvas.drawLine(
      Offset(radius, 0.5),
      Offset(size.width - radius, 0.5),
      highlight,
    );
  }

  @override
  bool shouldRepaint(_SheetEdgePainter oldDelegate) =>
      oldDelegate.radius != radius;
}

/// Segmented control for switching views inside sheets and cards. The
/// selected segment slides between positions.
class AppSegmented<T> extends StatelessWidget {
  final List<(T value, String label, IconData? icon)> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final Color? color;
  const AppSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;
    final found = segments.indexWhere((s) => s.$1 == value);
    final index = found < 0 ? 0 : found;
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / segments.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: width * index,
                top: 0,
                bottom: 0,
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tint.withAlpha(36),
                    borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                    border: Border.all(color: tint.withAlpha(110)),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final (segment, label, icon) in segments)
                    Expanded(
                      child: _segment(segment, label, icon, tint),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _segment(T segment, String label, IconData? icon, Color tint) {
    final selected = segment == value;
    final fg = selected ? tint : ColorName.greyText;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        onTap: selected ? null : () => onChanged(segment),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Opens [sheet] (usually an [AppSheet]) as a modal bottom sheet.
Future<T?> showAppSheet<T>(Widget sheet) {
  return Get.bottomSheet<T>(
    sheet,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

/// Tinted circular icon shown at the top of a dialog. Pops in when shown;
/// when [urgent] it also shakes once and keeps a soft pulsing halo.
class AppDialogIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  Color get _color => color ?? AppColors.primary;

  final bool urgent;
  const AppDialogIcon({
    super.key,
    required this.icon,
    this.color,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppPopIn(
      shake: urgent,
      delay: const Duration(milliseconds: 140),
      child: urgent
          ? AppBreathing(
              period: const Duration(milliseconds: 1400),
              builder: (context, v) => _badge(v),
            )
          : _badge(0),
    );
  }

  Widget _badge(double glow) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _color.withAlpha(30),
        shape: BoxShape.circle,
        border: Border.all(color: _color.withAlpha(70 + (80 * glow).round())),
        boxShadow: glow == 0
            ? null
            : [
                BoxShadow(
                  color: _color.withAlpha((70 * glow).round()),
                  blurRadius: 8 + 14 * glow,
                  spreadRadius: 4 * glow,
                ),
              ],
      ),
      child: Icon(icon, color: _color),
    );
  }
}

/// Tinted box with an icon for warnings and side notes inside dialogs.
class AppCallout extends StatelessWidget {
  final String text;
  final Color? color;
  Color get _color => color ?? AppColors.accent;

  final IconData icon;
  const AppCallout({
    super.key,
    required this.text,
    this.color,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withAlpha(22),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _color.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog chrome: optional icon badge, title, message/content and a row (or
/// stack) of actions, usually [AppSecondaryButton] and [AppPrimaryButton].
/// Set [urgent] for warnings (leaving, deleting, exposing secrets) so the icon
/// shakes and pulses.
class AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  Color get _iconColor => iconColor ?? AppColors.primary;

  final List<Widget> actions;
  final bool stackActions;
  final bool urgent;
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.iconColor,
    this.actions = const [],
    this.stackActions = false,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    var step = 0;
    return AppDialogMotion(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppDialogIcon(
                    icon: icon!,
                    color: _iconColor,
                    urgent: urgent,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              AppDialogStagger(
                index: step++,
                child: Text(title, style: AppText.title),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                AppDialogStagger(
                  index: step++,
                  child: Text(
                    message!,
                    style: AppText.muted.copyWith(height: 1.45),
                  ),
                ),
              ],
              if (content != null) ...[
                SizedBox(height: message == null ? 12 : 16),
                Flexible(
                  child: AppDialogStagger(
                    index: step++,
                    child: SingleChildScrollView(child: content!),
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                AppDialogStagger(
                  index: step++,
                  child: _actions(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions() {
    if (stackActions) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            actions[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: actions[i]),
        ],
      ],
    );
  }
}

/// Confirmation dialog. Resolves to true when confirmed.
Future<bool> showAppConfirm({
  required String title,
  String? message,
  InlineSpan? richMessage,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await Get.dialog<bool>(
    barrierDismissible: !destructive,
    AppDialog(
      title: title,
      message: richMessage == null ? message : null,
      content: richMessage == null
          ? null
          : Text.rich(
              richMessage,
              style: AppText.body.copyWith(height: 1.5),
            ),
      icon: destructive ? Icons.warning_amber_rounded : null,
      iconColor: destructive ? AppColors.danger : AppColors.primary,
      urgent: destructive,
      stackActions: cancelLabel.length + confirmLabel.length > 22,
      actions: [
        AppSecondaryButton(
          label: cancelLabel,
          onPressed: () => Get.closeOverlay(result: false),
        ),
        AppPrimaryButton(
          label: confirmLabel,
          color: destructive ? AppColors.danger : null,
          onPressed: () => Get.closeOverlay(result: true),
        ),
      ],
    ),
  );
  return result == true;
}
