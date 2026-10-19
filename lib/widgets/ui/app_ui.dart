import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podium/gen/colors.gen.dart';

/// Podium design kit: the look of the outpost call page, shared by every
/// screen. Prefer these over hand-rolled containers so screens stay
/// consistent.

class AppColors {
  AppColors._();

  static const success = Color(0xFF3DDC97);
  static const danger = Color(0xFFF04141);
  static const accent = Color(0xFFFFC857);
  static const primary = ColorName.primaryBlue;

  static const surface = ColorName.cardBackground;
  static const border = ColorName.cardBorder;
  static const textMuted = ColorName.greyText;
  static const textFaint = ColorName.secondaryText;

  /// Translucent card fill that lets the page gradient show through.
  static Color get surfaceGlass => ColorName.cardBackground.withAlpha(200);

  /// Fill for inputs, chips and icon buttons sitting on a surface.
  static Color get fill => Colors.white.withAlpha(12);
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? AppColors.border),
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: ShapeDecoration(
            shape: shape,
            color: gradient == null ? (color ?? AppColors.surfaceGlass) : null,
            gradient: gradient,
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
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
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.muted,
                  ),
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
    final fg = foreground ?? Colors.white;
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: color ?? AppColors.primary,
        foregroundColor: fg,
        disabledBackgroundColor: loading
            ? (color ?? AppColors.primary).withAlpha(150)
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
              fontSize: 11,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 52 : 72,
            height: compact ? 52 : 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(24),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Icon(
              icon,
              size: compact ? 24 : 32,
              color: AppColors.primary,
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
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(actionLabel ?? 'Try again'),
            ),
          ],
        ],
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
        color: ColorName.cardBackground,
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
    AlertDialog(
      title: Text(title),
      content: message == null
          ? null
          : Text(message, style: const TextStyle(color: AppColors.textMuted)),
      actions: [
        TextButton(
          onPressed: () => Get.closeOverlay(result: false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AppColors.danger : AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Get.closeOverlay(result: true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}
