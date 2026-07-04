import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kali_colors_extension.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();
  static const _themeModeKey = 'theme_mode';
  static const _themeIdKey = 'theme_id';

  ThemeMode _themeMode = ThemeMode.light;
  KaliColorsExtension _currentTheme = KaliColorsExtension.defaultTheme;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  KaliColorsExtension get currentTheme => _currentTheme;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeModeKey);
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    
    final savedThemeId = prefs.getString(_themeIdKey) ?? 'default';
    _applyThemeById(savedThemeId);
    notifyListeners();
  }

  void _applyThemeById(String themeId) {
    switch (themeId) {
      case 'dark':
        _currentTheme = KaliColorsExtension.darkTheme;
        break;
      case 'ocean':
        _currentTheme = KaliColorsExtension.oceanTheme;
        break;
      case 'nature':
        _currentTheme = KaliColorsExtension.natureTheme;
        break;
      case 'magenta':
        _currentTheme = KaliColorsExtension.magentaTheme;
        break;
      default:
        _currentTheme = KaliColorsExtension.defaultTheme;
        break;
    }
  }

  Future<void> syncTheme(String themeId) async {
    _applyThemeById(themeId);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeIdKey, themeId);
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, enabled ? 'dark' : 'light');
  }
}
