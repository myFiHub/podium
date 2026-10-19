import 'package:flutter/material.dart';
import 'package:podium/gen/colors.gen.dart';

class ConnectedAccountsConstants {
  static const double containerPadding = 16.0;
  static const double borderRadius = 18.0;
  static const double iconSize = 20.0;
  static const double headerIconSize = 22.0;
  static const double headerFontSize = 15.0;
  static const double identifierFontSize = 12.0;

  static const Color headerBackgroundColor = ColorName.success;
  static const int headerBackgroundAlpha = 22;
  static const Color successColor = ColorName.success;
  static const Color identifierColor = ColorName.greyText;
  static const Color primaryBlue = ColorName.primaryBlue;

  static const EdgeInsets defaultPadding = EdgeInsets.all(containerPadding);
  static const BorderRadius containerBorderRadius =
      BorderRadius.all(Radius.circular(borderRadius));
}
