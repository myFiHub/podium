import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:reown_appkit/reown_appkit.dart';

ButtonStyle buttonStyle(BuildContext context) {
  final themeColors = ReownAppKitModalTheme.colorsOf(context);
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color>(
      (states) {
        if (states.contains(WidgetState.disabled)) {
          return ReownAppKitModalTheme.colorsOf(context).background225;
        }
        return ReownAppKitModalTheme.colorsOf(context).accent100;
      },
    ),
    shape: WidgetStateProperty.resolveWith<RoundedRectangleBorder>(
      (states) {
        return RoundedRectangleBorder(
          side: states.contains(WidgetState.disabled)
              ? BorderSide(color: themeColors.grayGlass005, width: 1.0)
              : BorderSide(color: themeColors.grayGlass010, width: 1.0),
          borderRadius: borderRadius(context),
        );
      },
    ),
    textStyle: WidgetStateProperty.resolveWith<TextStyle>(
      (states) {
        return ReownAppKitModalTheme.getDataOf(context)
            .textStyles
            .small600
            .copyWith(
              color: (states.contains(WidgetState.disabled))
                  ? ReownAppKitModalTheme.colorsOf(context).foreground300
                  : ReownAppKitModalTheme.colorsOf(context).inverse100,
            );
      },
    ),
    foregroundColor: WidgetStateProperty.resolveWith<Color>(
      (states) {
        return (states.contains(WidgetState.disabled))
            ? ReownAppKitModalTheme.colorsOf(context).foreground300
            : ReownAppKitModalTheme.colorsOf(context).inverse100;
      },
    ),
  );
}

BorderRadiusGeometry borderRadius(BuildContext context) {
  final radiuses = ReownAppKitModalTheme.radiusesOf(context);
  return radiuses.isSquare()
      ? const BorderRadius.all(Radius.zero)
      : radiuses.isCircular()
          ? BorderRadius.circular(1000.0)
          : BorderRadius.circular(8.0);
}

final defaultAppBar = AppBar(
  iconTheme: IconThemeData(color: ColorName.primaryBlue),
  backgroundColor: ColorName.pageBackground,
);

const vSpace10 = const SizedBox(height: 10);
const space10 = const Gap(
  10,
);
const space5 = const Gap(5);
