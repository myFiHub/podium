import 'package:flutter/material.dart';
import 'package:podium/utils/palette.dart';
import 'package:podium/utils/theme.dart';
import 'package:podium/widgets/ui/app_ui.dart';

/// Lets the user pick one of [AppPalette.all]. The app restyles live, so the
/// sheet stays open to compare themes.
class ColorThemeSheet extends StatelessWidget {
  const ColorThemeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Color theme',
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: AppSheet.maxHeight(context, 0.7)),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: AppPalette.all.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final palette = AppPalette.all[index];
            return _PaletteOption(
              palette: palette,
              selected: palette.id == AppPalette.current.id,
            );
          },
        ),
      ),
    );
  }
}

class _PaletteOption extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  const _PaletteOption({required this.palette, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          AppPalette.select(palette, buildTheme: buildThemeData);
        },
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.fill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              _PalettePreview(palette: palette),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(palette.name, style: AppText.cardTitle),
                    const SizedBox(height: 2),
                    Text(palette.description, style: AppText.caption),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniature of a screen in [palette]: page, card, text lines and an accent
/// button, drawn in that palette's own colors.
class _PalettePreview extends StatelessWidget {
  final AppPalette palette;
  const _PalettePreview({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: palette.border),
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Line(color: palette.text, width: 40),
            _Line(color: palette.textFaint, width: 28),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.magenta,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final Color color;
  final double width;
  const _Line({required this.color, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
