import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kali_colors_extension.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();
  static const _themeModeKey = 'theme_mode';
  static const _themeIdKey = 'theme_id';

  ThemeMode _themeMode = ThemeMode.light;
  String _themeId = 'default';
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
    
    _themeId = prefs.getString(_themeIdKey) ?? 'default';
    _updateCurrentTheme();
    notifyListeners();
  }

  void _updateCurrentTheme() {
    switch (_themeId) {
      case 'ocean':
        _currentTheme = isDarkMode ? KaliColorsExtension.oceanDarkTheme : KaliColorsExtension.oceanTheme;
        break;
      case 'nature':
        _currentTheme = isDarkMode ? KaliColorsExtension.natureDarkTheme : KaliColorsExtension.natureTheme;
        break;
      case 'magenta':
        _currentTheme = isDarkMode ? KaliColorsExtension.magentaDarkTheme : KaliColorsExtension.magentaTheme;
        break;
      case 'dark':
        _currentTheme = KaliColorsExtension.darkTheme;
        break;
      default:
        _currentTheme = isDarkMode ? KaliColorsExtension.darkTheme : KaliColorsExtension.defaultTheme;
        break;
    }
  }

  Future<void> syncTheme(String themeId) async {
    _themeId = themeId;
    _updateCurrentTheme();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeIdKey, themeId);
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    _updateCurrentTheme();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, enabled ? 'dark' : 'light');
  }
}
