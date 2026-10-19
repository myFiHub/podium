import 'package:flutter/material.dart';
import 'package:podium/gen/colors.gen.dart';
import 'package:podium/gen/fonts.gen.dart';

const _radius = 14.0;
const _danger = ColorName.danger;
const _onPrimary = ColorName.cardBackground;
const _surfaceRaised = Color(0xFF1B1B36);

final ThemeData darkThemeData = ThemeData(
  fontFamily: FontFamily.sora,
  primarySwatch: Colors.blue,
  colorScheme: const ColorScheme.dark(
    primary: ColorName.primaryBlue,
    onPrimary: _onPrimary,
    secondary: ColorName.primaryBlue,
    onSecondary: _onPrimary,
    surface: ColorName.cardBackground,
    onSurface: Colors.white,
    surfaceContainerHighest: ColorName.cardBorder,
    outline: ColorName.cardBorder,
    outlineVariant: ColorName.cardBorder,
    error: _danger,
  ),
  scaffoldBackgroundColor: Colors.transparent,
  highlightColor: ColorName.primaryBlue.withAlpha(30),
  hintColor: ColorName.greyText,
  primaryColor: ColorName.black,
  splashColor: ColorName.primaryBlue.withAlpha(40),
  canvasColor: Colors.transparent,
  dividerColor: ColorName.cardBorder,
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.normal),
    labelSmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
  ).apply(
    bodyColor: ColorName.white,
    displayColor: ColorName.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      fontFamily: FontFamily.sora,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ColorName.primaryBlue,
      foregroundColor: _onPrimary,
      disabledBackgroundColor: Colors.white.withAlpha(18),
      disabledForegroundColor: Colors.white.withAlpha(90),
      textStyle: const TextStyle(
        fontFamily: FontFamily.sora,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ColorName.primaryBlue,
      foregroundColor: _onPrimary,
      elevation: 0,
      textStyle: const TextStyle(
        fontFamily: FontFamily.sora,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: ColorName.cardBorder),
      textStyle: const TextStyle(
        fontFamily: FontFamily.sora,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ColorName.primaryBlue,
      textStyle: const TextStyle(
        fontFamily: FontFamily.sora,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withAlpha(10),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    hintStyle: const TextStyle(color: ColorName.greyText, fontSize: 14),
    labelStyle: const TextStyle(color: ColorName.greyText),
    floatingLabelStyle: const TextStyle(color: ColorName.primaryBlue),
    prefixIconColor: ColorName.greyText,
    suffixIconColor: ColorName.greyText,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: const BorderSide(color: ColorName.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: const BorderSide(color: ColorName.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: const BorderSide(color: ColorName.primaryBlue, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: const BorderSide(color: _danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: const BorderSide(color: _danger, width: 1.4),
    ),
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: ColorName.primaryBlue,
    selectionColor: ColorName.primaryBlue.withAlpha(90),
    selectionHandleColor: ColorName.primaryBlue,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: _surfaceRaised,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: ColorName.cardBorder),
    ),
    titleTextStyle: const TextStyle(
      fontFamily: FontFamily.sora,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    contentTextStyle: const TextStyle(
      fontFamily: FontFamily.sora,
      fontSize: 14,
      color: ColorName.greyText,
      height: 1.4,
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    modalBackgroundColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    color: ColorName.cardBackground,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: ColorName.cardBorder),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white.withAlpha(12),
    selectedColor: ColorName.primaryBlue.withAlpha(60),
    side: const BorderSide(color: ColorName.cardBorder),
    labelStyle: const TextStyle(
      fontFamily: FontFamily.sora,
      fontSize: 12,
      color: Colors.white,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: _surfaceRaised,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: ColorName.cardBorder),
    ),
    textStyle: const TextStyle(fontFamily: FontFamily.sora, fontSize: 14),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: _surfaceRaised,
    contentTextStyle: const TextStyle(
      fontFamily: FontFamily.sora,
      color: Colors.white,
    ),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: ColorName.cardBorder),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: ColorName.cardBorder,
    thickness: 1,
    space: 1,
  ),
  listTileTheme: const ListTileThemeData(
    iconColor: ColorName.greyText,
    textColor: Colors.white,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? Colors.white
          : ColorName.greyText,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? ColorName.primaryBlue
          : Colors.white.withAlpha(20),
    ),
    trackOutlineColor: WidgetStateProperty.all(ColorName.cardBorder),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? ColorName.primaryBlue
          : Colors.transparent,
    ),
    side: const BorderSide(color: ColorName.greyText, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? ColorName.primaryBlue
          : ColorName.greyText,
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: ColorName.primaryBlue,
    linearTrackColor: ColorName.cardBorder,
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: Colors.white,
    unselectedLabelColor: ColorName.greyText,
    dividerColor: Colors.transparent,
    indicatorSize: TabBarIndicatorSize.tab,
    labelStyle: const TextStyle(
      fontFamily: FontFamily.sora,
      fontWeight: FontWeight.w700,
      fontSize: 13,
    ),
    unselectedLabelStyle: const TextStyle(
      fontFamily: FontFamily.sora,
      fontWeight: FontWeight.w500,
      fontSize: 13,
    ),
    indicator: BoxDecoration(
      color: ColorName.primaryBlue.withAlpha(40),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ColorName.primaryBlue.withAlpha(90)),
    ),
  ),
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: _surfaceRaised,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: ColorName.cardBorder),
    ),
    textStyle: const TextStyle(
      fontFamily: FontFamily.sora,
      fontSize: 12,
      color: Colors.white,
    ),
  ),
);
