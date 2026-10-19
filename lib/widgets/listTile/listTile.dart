import 'package:flutter/material.dart';
import 'package:podium/gen/colors.gen.dart';

class PodiumListTile extends StatelessWidget {
  /// Creates ListTile with leading, title, trailing, image widget for almost every type of ListTile design.
  const PodiumListTile({
    Key? key,
    this.titleText,
    this.subTitleText,
    this.color,
    this.avatar,
    this.title,
    this.subTitle,
    this.description,
    this.icon,
    this.padding = const EdgeInsets.all(12),
    this.margin = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    this.listItemTextColor = ColorName.white,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.focusColor,
    this.hoverColor,
    this.focusNode,
    this.autofocus = false,
    this.firstButtonTitle,
    this.secondButtonTitle,
    this.onFirstButtonTap,
    this.onSecondButtonTap,
    this.firstButtonTextStyle,
    this.secondButtonTextStyle,
    this.radius,
    this.shadow,
  }) : super(key: key);

  /// type of [String] used to pass text, alternative to title property and gets higher priority than title
  final String? titleText;

  /// type of [String] used to pass text, alternative to subTitle property and gets higher priority than subTitle
  final String? subTitleText;

  /// The GFListTile's background color. Can be given [Color] or [GFColors]
  final Color? color;

  /// type of [Widget] or [GFAvatar] used to create rounded user profile
  final Widget? avatar;

  /// The title to display inside the [PodiumListTile]. see [Text]
  final Widget? title;

  /// The subTitle to display inside the [PodiumListTile]. see [Text]
  final Widget? subTitle;

  /// The description to display inside the [PodiumListTile]. see [Text]
  final Widget? description;

  /// The icon to display inside the [PodiumListTile]. see [Icon]
  final Widget? icon;

  /// defines the margin of GFListTile
  final EdgeInsets margin;

  /// defines the padding of GFListTile
  final EdgeInsets padding;

  /// Whether this list tile is interactive.
  ///
  /// If false, this list tile is styled with the disabled color from the
  /// current [Theme] and the [onTap] and [onLongPress] callbacks are
  /// inoperative.
  final bool enabled;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;

  /// Called when the user long-presses on this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureLongPressCallback? onLongPress;

  /// If this tile is also [enabled] then icons and text are rendered with the same color.
  ///
  /// By default the selected color is the theme's primary color. The selected color
  /// can be overridden with a [ListTileTheme].
  final bool selected;

  /// The color for the tile's [Material] when it has the input focus.
  final Color? focusColor;

  /// The color for the color of the list item text.
  final Color? listItemTextColor;

  /// The color for the tile's [Material] when a pointer is hovering over it.
  final Color? hoverColor;

  /// Defines the keyboard focus for this widget.
  final FocusNode? focusNode;

  /// On true state it should focus itself if nothing else is already focused.
  /// Defaults to false
  final bool autofocus;

  /// The firstButtonTitle to display inside the [PodiumListTile]. see [Text]
  final String? firstButtonTitle;

  /// The secondButtonTitle to display inside the [PodiumListTile]. see [Text]
  final String? secondButtonTitle;

  /// The style for the firstButtonText.
  final TextStyle? firstButtonTextStyle;

  /// The style for the secondButtonText.
  final TextStyle? secondButtonTextStyle;

  /// Called when the user taps on the first button.
  final GestureTapCallback? onFirstButtonTap;

  /// Called when the user taps on the second button.
  final GestureTapCallback? onSecondButtonTap;

  /// the circular radius of [PodiumListTile]
  final double? radius;

  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius ?? 14);
    final hasButtons = (firstButtonTitle?.isNotEmpty ?? false) ||
        (secondButtonTitle?.isNotEmpty ?? false);
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          canRequestFocus: enabled,
          focusNode: focusNode,
          focusColor: focusColor,
          hoverColor: hoverColor,
          autofocus: autofocus,
          child: Semantics(
            selected: selected,
            enabled: enabled,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: color != null
                    ? Border.all(color: ColorName.cardBorder)
                    : null,
                boxShadow: shadow != null ? [shadow!] : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: <Widget>[
                      if (avatar != null) avatar!,
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (titleText != null)
                                Text(
                                  titleText!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: listItemTextColor,
                                  ),
                                )
                              else if (title != null)
                                title!,
                              if (subTitleText != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    subTitleText!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: ColorName.greyText,
                                    ),
                                  ),
                                )
                              else if (subTitle != null)
                                subTitle!,
                              if (description != null) description!,
                            ],
                          ),
                        ),
                      ),
                      if (icon != null) icon!,
                    ],
                  ),
                  if (hasButtons)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (firstButtonTitle?.isNotEmpty ?? false)
                            TextButton(
                              onPressed: onFirstButtonTap,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: ColorName.greyText,
                              ),
                              child: Text(
                                firstButtonTitle ?? '',
                                style: firstButtonTextStyle,
                              ),
                            ),
                          if (secondButtonTitle?.isNotEmpty ?? false)
                            TextButton(
                              onPressed: onSecondButtonTap,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: ColorName.primaryBlue,
                              ),
                              child: Text(
                                secondButtonTitle ?? '',
                                style: secondButtonTextStyle,
                              ),
                            ),
                        ],
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
