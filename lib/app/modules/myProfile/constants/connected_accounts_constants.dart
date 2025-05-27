import 'package:flutter/material.dart';
import 'package:podium/gen/colors.gen.dart';

class ConnectedAccountsConstants {
  static const double containerPadding = 16.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 20.0;
  static const double headerIconSize = 24.0;
  static const double headerFontSize = 14.0;
  static const double identifierFontSize = 10.0;

  static const Color headerBackgroundColor = ColorName.black;
  static const int headerBackgroundAlpha = 26;
  static const Color successColor = Colors.green;
  static const Color identifierColor = Colors.indigo;
  static const Color primaryBlue = ColorName.primaryBlue;

  static const EdgeInsets defaultPadding = EdgeInsets.all(containerPadding);
  static const BorderRadius containerBorderRadius =
      BorderRadius.all(Radius.circular(borderRadius));
}
