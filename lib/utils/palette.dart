import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:podium/utils/storage.dart';

/// One selectable color theme. Every screen reads colors through [ColorName],
/// which resolves against [AppPalette.current].
class AppPalette {
  final String id;
  final String name;
  final String description;
  final bool isLight;
  final Color background;
  final Color navbar;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color accent;
  final Color onAccent;
  final Color accentSecondary;

  /// Secondary and tertiary hues of the brand gradients and the aurora glow.
  final Color violet;
  final Color magenta;
  final Color success;
  final Color warning;
  final Color danger;

  /// Strength of the drifting aurora background glow, 0..1.
  final double glow;

  const AppPalette({
    required this.id,
    required this.name,
    required this.description,
    required this.isLight,
    required this.background,
    required this.navbar,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.onAccent,
    required this.accentSecondary,
    required this.violet,
    required this.magenta,
    required this.success,
    required this.warning,
    required this.danger,
    required this.glow,
  });

  static const aurora = AppPalette(
    id: 'aurora',
    name: 'Aurora',
    description: 'Cyan, violet and magenta glow',
    isLight: false,
    background: Color(0xFF0B0B1E),
    navbar: Color(0xFF0E0E26),
    surface: Color(0xFF14142B),
    surfaceRaised: Color(0xFF1B1B36),
    border: Color(0xFF2A2A40),
    borderStrong: Color(0xFF5D6583),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFC1C1C4),
    textFaint: Color(0xFF8A93B5),
    accent: Color(0xFF54E4EF),
    onAccent: Color(0xFF14142B),
    accentSecondary: Color(0xFF4579FD),
    violet: Color(0xFF8B5CF6),
    magenta: Color(0xFFFF4FD8),
    success: Color(0xFF3DDC97),
    warning: Color(0xFFFFC857),
    danger: Color(0xFFF04141),
    glow: 1,
  );

  static const onAir = AppPalette(
    id: 'onAir',
    name: 'On Air',
    description: 'Warm graphite with a vermilion accent',
    isLight: false,
    background: Color(0xFF131211),
    navbar: Color(0xFF161514),
    surface: Color(0xFF1C1A18),
    surfaceRaised: Color(0xFF25221F),
    border: Color(0xFF302C28),
    borderStrong: Color(0xFF5A534B),
    text: Color(0xFFF3EEE7),
    textMuted: Color(0xFFC2BAB0),
    textFaint: Color(0xFF8F877D),
    accent: Color(0xFFFF5B3A),
    onAccent: Color(0xFF1A0C07),
    accentSecondary: Color(0xFFF2C14E),
    violet: Color(0xFFE8794F),
    magenta: Color(0xFFF2C14E),
    success: Color(0xFF7BC47F),
    warning: Color(0xFFF2C14E),
    danger: Color(0xFFD9363E),
    glow: 0.25,
  );

  static const brass = AppPalette(
    id: 'brass',
    name: 'Brass Studio',
    description: 'Matte black with brass gold',
    isLight: false,
    background: Color(0xFF0F0F10),
    navbar: Color(0xFF131315),
    surface: Color(0xFF18181A),
    surfaceRaised: Color(0xFF202023),
    border: Color(0xFF2C2C30),
    borderStrong: Color(0xFF55555C),
    text: Color(0xFFEDEAE4),
    textMuted: Color(0xFFC4C0B8),
    textFaint: Color(0xFF8E8A83),
    accent: Color(0xFFD9A54A),
    onAccent: Color(0xFF1A1408),
    accentSecondary: Color(0xFF8FA8C8),
    violet: Color(0xFFB98A3E),
    magenta: Color(0xFFE08A3C),
    success: Color(0xFF6FBF8E),
    warning: Color(0xFFE08A3C),
    danger: Color(0xFFE5484D),
    glow: 0.2,
  );

  static const deepTeal = AppPalette(
    id: 'deepTeal',
    name: 'Deep Teal',
    description: 'Muted teal with a warm apricot',
    isLight: false,
    background: Color(0xFF0B1214),
    navbar: Color(0xFF0E1618),
    surface: Color(0xFF121B1E),
    surfaceRaised: Color(0xFF182427),
    border: Color(0xFF243236),
    borderStrong: Color(0xFF4A5F63),
    text: Color(0xFFE8EEEC),
    textMuted: Color(0xFFBCC8C5),
    textFaint: Color(0xFF879A96),
    accent: Color(0xFF3FB8A6),
    onAccent: Color(0xFF062320),
    accentSecondary: Color(0xFF5B9BD5),
    violet: Color(0xFF2E8C88),
    magenta: Color(0xFFF2A65A),
    success: Color(0xFF5FBF7A),
    warning: Color(0xFFE9B949),
    danger: Color(0xFFE5534B),
    glow: 0.35,
  );

  static const paper = AppPalette(
    id: 'paper',
    name: 'Paper',
    description: 'Light: warm paper with ink blue',
    isLight: true,
    background: Color(0xFFF4F0E8),
    navbar: Color(0xFFEFEAE0),
    surface: Color(0xFFFBF8F2),
    surfaceRaised: Color(0xFFFFFFFF),
    border: Color(0xFFE2DCD0),
    borderStrong: Color(0xFFB9B0A2),
    text: Color(0xFF1B1A17),
    textMuted: Color(0xFF4A463F),
    textFaint: Color(0xFF7A7368),
    accent: Color(0xFF2A4BD7),
    onAccent: Color(0xFFFFFFFF),
    accentSecondary: Color(0xFF1F7A6B),
    violet: Color(0xFF4A63E0),
    magenta: Color(0xFFE4572E),
    success: Color(0xFF2F8F5B),
    warning: Color(0xFFB7791F),
    danger: Color(0xFFC8372D),
    glow: 0,
  );

  static const all = [aurora, onAir, brass, deepTeal, paper];

  static AppPalette _current = aurora;
  static AppPalette get current => _current;

  /// Restores the saved palette. Call after [GetStorage.init].
  static void load() {
    final id = GetStorage().read<String>(StorageKeys.colorTheme);
    _current = all.firstWhere((p) => p.id == id, orElse: () => aurora);
    applySystemUi();
  }

  /// Switches the whole app to [palette] and remembers the choice.
  static Future<void> select(
    AppPalette palette, {
    required ThemeData Function() buildTheme,
  }) async {
    if (palette.id == _current.id) return;
    _current = palette;
    GetStorage().write(StorageKeys.colorTheme, palette.id);
    applySystemUi();
    Get.changeTheme(buildTheme());
    await Get.forceAppUpdate();
  }

  @visibleForTesting
  static void debugSet(AppPalette palette) => _current = palette;

  static void applySystemUi() {
    final iconBrightness =
        _current.isLight ? Brightness.dark : Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _current.background,
        systemNavigationBarColor: _current.navbar,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness:
            _current.isLight ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
    );
  }
}

/// Named app colors, resolved against the active [AppPalette].
class ColorName {
  ColorName._();

  static AppPalette get _p => AppPalette.current;

  static Color get pageBackground => _p.background;
  static Color get systemTrayBackground => _p.background;
  static Color get navbarBackground => _p.navbar;
  static Color get cardBackground => _p.surface;
  static Color get cardBorder => _p.border;
  static Color get buttonOutlineBorder => _p.borderStrong;
  static Color get pageBgGradientStart => _p.surfaceRaised;
  static Color get pageBgGradientEnd => _p.background;

  /// Primary foreground (text and icons). Dark ink on light palettes.
  static Color get white => _p.text;
  static Color get primarytext => _p.text;
  static Color get greyText => _p.textMuted;
  static Color get secondaryText => _p.textFaint;

  static Color get primaryBlue => _p.accent;
  static Color get secondaryBlue => _p.accentSecondary;
  static Color get auroraViolet => _p.violet;
  static Color get auroraMagenta => _p.magenta;

  static Color get success => _p.success;
  static Color get danger => _p.danger;
  static Color get warning => _p.warning;

  static const Color black = Color(0xFF000000);
}
