import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'kali_colors_extension.dart';
import 'theme_controller.dart';

class KaliColors {
  static KaliColorsExtension get _ext => ThemeController.instance.currentTheme;

  static Color get espresso => _ext.espresso;
  static Color get espressoL => _ext.espressoL;
  static Color get clay => _ext.clay;
  static Color get clayDark => _ext.clayDark;
  static Color get sand => _ext.sand;
  static Color get sand2 => _ext.sand2;
  static Color get sage => _ext.sage;
  static Color get sageLight => _ext.sageLight;
  static Color get warmWhite => _ext.warmWhite;
  static Color get background => _ext.background;
}

class KaliText {
  static KaliColorsExtension get _ext => ThemeController.instance.currentTheme;

  static TextStyle display(Color color) => _ext.typography.display(color);
  static TextStyle loginDisplay(Color color) => _ext.typography.loginDisplay(color);
  static TextStyle buttonText(Color color) => _ext.typography.loginBodyBase.copyWith(fontSize: 18, color: color, fontWeight: FontWeight.bold);

  static TextStyle heading(Color color, {double size = 24}) => _ext.typography.heading(color, size: size);
  static TextStyle headingItalic(Color color, {double size = 26}) => _ext.typography.headingItalic(color, size: size);
  static TextStyle body(Color color, {double size = 13, FontWeight weight = FontWeight.w400}) => _ext.typography.body(color, size: size, weight: weight);
  static TextStyle label(Color color) => _ext.typography.label(color);
  static TextStyle caption(Color color) => _ext.typography.caption(color);
}

class KaliTheme {
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData buildTheme(KaliColorsExtension colors, {bool isDark = false}) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.warmWhite,
      pageTransitionsTheme: _pageTransitions,
      colorScheme: isDark 
          ? ColorScheme.dark(
              primary: colors.espresso,
              secondary: colors.clay,
              surface: colors.warmWhite,
            )
          : ColorScheme.light(
              primary: colors.espresso,
              secondary: colors.clay,
              surface: colors.warmWhite,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.espresso,
        foregroundColor: colors.warmWhite,
        elevation: 0,
        centerTitle: true,
      ),
      extensions: [colors],
    );
  }

  static ThemeData get theme => buildTheme(ThemeController.instance.currentTheme, isDark: false);
  static ThemeData get darkTheme => buildTheme(ThemeController.instance.currentTheme, isDark: true);
}
