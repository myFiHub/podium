import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/widgets/ui/aurora.dart';

export 'package:podium/widgets/ui/aurora.dart';

/// Podium design kit: the look of the outpost call page, shared by every
/// screen. Prefer these over hand-rolled containers so screens stay
/// consistent.

class AppColors {
  AppColors._();

  static const success = ColorName.success;
  static const danger = ColorName.danger;
  static const accent = ColorName.warning;
  static const live = ColorName.danger;
  static const primary = ColorName.primaryBlue;
  static const violet = ColorName.auroraViolet;
  static const magenta = ColorName.auroraMagenta;

  /// Text/icons on [primary] fills. The primary cyan is too light for white
  /// text to be legible.
  static const onPrimary = ColorName.cardBackground;

  static const surface = ColorName.cardBackground;

  /// Slightly lifted surface for sheets, dialogs and popovers.
  static const surfaceRaised = Color(0xFF1B1B36);
  static const border = ColorName.cardBorder;
  static const textMuted = ColorName.greyText;
  static const textFaint = ColorName.secondaryText;

  /// Translucent card fill that lets the page gradient show through.
  static Color get surfaceGlass => ColorName.cardBackground.withAlpha(200);

  /// Fill for inputs, chips and icon buttons sitting on a surface.
  static Color get fill => Colors.white.withAlpha(12);

  /// Legible text/icon color for content drawn on a solid [background].
  static Color onColor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.light
          ? onPrimary
          : Colors.white;
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

  static const pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: Colors.white,
  );
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const body = TextStyle(fontSize: 14, color: Colors.white, height: 1.4);
  static const muted = TextStyle(fontSize: 13, color: ColorName.greyText);
  static const caption = TextStyle(fontSize: 12, color: ColorName.greyText);
  static const label = TextStyle(
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
    this.radius = AppRadius.lg,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final glowBorder = borderColor == null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: glowBorder ? BorderSide.none : BorderSide(color: borderColor!),
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: AppPressScale(
        enabled: onTap != null,
        scale: 0.985,
        child: CustomPaint(
          foregroundPainter:
              glowBorder ? GradientBorderPainter(radius: radius) : null,
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
        foregroundColor: color ?? Colors.white,
        side: const BorderSide(color: AppColors.border),
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
                                end: active ? AppColors.primary : Colors.white,
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
            : Colors.white.withAlpha(18),
        disabledForegroundColor: loading ? fg : Colors.white.withAlpha(90),
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
  final Gradient gradient;
  const AppGradientShell({
    super.key,
    required this.child,
    required this.borderRadius,
    this.enabled = true,
    this.gradient = AppGradients.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return AppPressScale(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
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
    final fg = color ?? Colors.white;
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
  final Color color;
  final IconData? icon;
  final bool filled;
  const AppPill({
    super.key,
    required this.label,
    this.color = ColorName.greyText,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(filled ? 255 : 70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: filled ? Colors.black : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.black : color,
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

/// Bottom sheet chrome: grabber, optional title row, safe-area padding.
class AppSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsets padding;
  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 20),
  });

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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: ColorName.cardBorder)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorName.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(child: Text(title!, style: AppText.title)),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            Flexible(child: Padding(padding: padding, child: child)),
          ],
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

/// Tinted circular icon shown at the top of a dialog.
class AppDialogIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const AppDialogIcon({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Icon(icon, color: color),
    );
  }
}

/// Tinted box with an icon for warnings and side notes inside dialogs.
class AppCallout extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const AppCallout({
    super.key,
    required this.text,
    this.color = AppColors.accent,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: color,
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
class AppDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final Color iconColor;
  final List<Widget> actions;
  final bool stackActions;
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.iconColor = AppColors.primary,
    this.actions = const [],
    this.stackActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                child: AppDialogIcon(icon: icon!, color: iconColor),
              ),
              const SizedBox(height: 14),
            ],
            Text(title, style: AppText.title),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!, style: AppText.muted.copyWith(height: 1.45)),
            ],
            if (content != null) ...[
              SizedBox(height: message == null ? 12 : 16),
              Flexible(child: SingleChildScrollView(child: content!)),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              if (stackActions)
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  actions[i],
                ]
              else
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirmation dialog. Resolves to true when confirmed.
Future<bool> showAppConfirm({
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await Get.dialog<bool>(
    AppDialog(
      title: title,
      message: message,
      icon: destructive ? Icons.warning_amber_rounded : null,
      iconColor: destructive ? AppColors.danger : AppColors.primary,
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
