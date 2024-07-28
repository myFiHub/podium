import 'package:flutter/material.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/gen/fonts.gen.dart';

final ThemeData darkThemeData = ThemeData(
  fontFamily: FontFamily.sora,
  primarySwatch: Colors.blue,
  // brightness: Brightness.dark,
  // brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.transparent,
  highlightColor: ColorName.primaryBlue,
  hintColor: ColorName.greyText,
  primaryColor: ColorName.black,
  splashColor: ColorName.primaryBlue.shade300,
  canvasColor: Colors.transparent,
  textTheme: const TextTheme(
    headlineLarge: const TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
    headlineMedium:
        const TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold),
    headlineSmall: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
    bodyLarge: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.normal),
    bodyMedium: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
    bodySmall: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
  ).apply(
    bodyColor: ColorName.white,
    displayColor: ColorName.white,
  ),
);
