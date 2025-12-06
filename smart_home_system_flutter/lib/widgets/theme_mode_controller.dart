import 'package:flutter/material.dart';
import '../models/theme_mode_setting.dart';
import '../models/font_size_setting.dart';


class ThemeModeController extends ChangeNotifier {
  //Theme
  ThemeModeSetting _mode = ThemeModeSetting.light;
  ThemeModeSetting get mode => _mode;

  void setMode(ThemeModeSetting newMode) {
    _mode = newMode;
    notifyListeners();
  }

  //Font
  ThemeFontSetting _fontSize = ThemeFontSetting.normal;
  ThemeFontSetting get fontSize => _fontSize;

  void setFontSize(ThemeFontSetting newSize) {
    _fontSize = newSize;
    notifyListeners();
  }

  double get resolvedFontSize {
    switch (_fontSize) {
      case ThemeFontSetting.normal:
        return 24.0;
      case ThemeFontSetting.large:
        return 48.0;
    }
  }

  ThemeMode get materialThemeMode {
    return _mode == ThemeModeSetting.light
        ? ThemeMode.light
        : ThemeMode.dark;
  }
}