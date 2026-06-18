import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_controller.dart';

// ─── Paleta de colores ────────────────────────────────────────────────────────
class KaliColors {
  static const Color _lightEspresso = Color(0xFF2C1F14);
  static const Color _darkEspresso = Color(0xFFF1E4D7);
  static const Color _lightEspressoL = Color(0xFF3D2B1A);
  static const Color _darkEspressoL = Color(0xFFD8C0AC);
  static const Color _lightClay = Color(0xFFC4A882);
  static const Color _darkClay = Color(0xFFD6B494);
  static const Color _lightClayDark = Color(0xFFA08060);
  static const Color _darkClayDark = Color(0xFFBDA38A);
  static const Color _lightSand = Color(0xFFF5F0E8);
  static const Color _darkSand = Color(0xFF231C19);
  static const Color _lightSand2 = Color(0xFFEDE6D8);
  static const Color _darkSand2 = Color(0xFF352B26);
  static const Color _lightSage = Color(0xFF8A9E88);
  static const Color _darkSage = Color(0xFF9FB29D);
  static const Color _lightSageLight = Color(0xFFD4DDD3);
  static const Color _darkSageLight = Color(0xFF324038);
  static const Color _lightWarmWhite = Color(0xFFFAF7F2);
  static const Color _darkWarmWhite = Color(0xFF161210);
  static const Color _lightBackground = Color(0xFFE8E2D8);
  static const Color _darkBackground = Color(0xFF120F0D);

  static bool get _isDark => ThemeController.instance.isDarkMode;

  static Color get espresso => _isDark ? _darkEspresso : _lightEspresso;
  static Color get espressoL => _isDark ? _darkEspressoL : _lightEspressoL;
  static Color get clay => _isDark ? _darkClay : _lightClay;
  static Color get clayDark => _isDark ? _darkClayDark : _lightClayDark;
  static Color get sand => _isDark ? _darkSand : _lightSand;
  static Color get sand2 => _isDark ? _darkSand2 : _lightSand2;
  static Color get sage => _isDark ? _darkSage : _lightSage;
  static Color get sageLight => _isDark ? _darkSageLight : _lightSageLight;
  static Color get warmWhite => _isDark ? _darkWarmWhite : _lightWarmWhite;
  static Color get background => _isDark ? _darkBackground : _lightBackground;
}

// ─── TextStyles ───────────────────────────────────────────────────────────────
class KaliText {
  static TextStyle display(Color color) => GoogleFonts.cormorantGaramond(
        fontSize: 36,
        fontWeight: FontWeight.w300,
        color: color,
        fontStyle: FontStyle.italic,
      );

  static TextStyle loginDisplay(Color color) => GoogleFonts.newsreader(
      fontSize: 48, color: color, fontStyle: FontStyle.italic);
  static TextStyle buttonText(Color color) => GoogleFonts.manrope(
      fontSize: 18, color: color, fontWeight: FontWeight.bold);

  static TextStyle heading(Color color, {double size = 24}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w300,
        color: color,
      );

  static TextStyle headingItalic(Color color, {double size = 26}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w300,
        color: color,
        fontStyle: FontStyle.italic,
      );

  static TextStyle body(Color color,
          {double size = 13, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);

  static TextStyle label(Color color) => GoogleFonts.dmSans(
        fontSize: 9,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.4,
        color: color,
      );

  static TextStyle caption(Color color) => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        color: color,
      );
}

// ─── Tema global ──────────────────────────────────────────────────────────────
class KaliTheme {
  // Transiciones de página suaves (zoom de Material) en todas las plataformas,
  // para que los push nativos no se sientan abruptos.
  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: KaliColors.warmWhite,
        pageTransitionsTheme: _pageTransitions,
        colorScheme: ColorScheme.light(
          primary: KaliColors.espresso,
          secondary: KaliColors.clay,
          surface: KaliColors.warmWhite,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: KaliColors.espresso,
          foregroundColor: KaliColors.warmWhite,
          elevation: 0,
          centerTitle: true,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF161210),
        pageTransitionsTheme: _pageTransitions,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8D4C0),
          secondary: Color(0xFFC8A989),
          surface: Color(0xFF161210),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161210),
          foregroundColor: Color(0xFFF7F1E8),
          elevation: 0,
          centerTitle: true,
        ),
      );
}
