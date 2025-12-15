import 'package:flutter/material.dart';
import '../models/theme_mode_setting.dart';


class ThemeModeController extends ChangeNotifier {
  //Theme
  ThemeModeSetting _mode = ThemeModeSetting.light;
  ThemeModeSetting get mode => _mode;

  void setMode(ThemeModeSetting newMode) {
    _mode = newMode;
    notifyListeners();
  }

  //Colors
  ThemeColorSetting _colorSetting = ThemeColorSetting.blues;
  ThemeColorSetting get colorSetting => _colorSetting;

  void setColor(ThemeColorSetting newColor) {
    _colorSetting = newColor;
    notifyListeners();
  }

  Color get backgroundColor {
    switch (_colorSetting) {
      case ThemeColorSetting.blues: 
        return Color(0XFF9DB2BF);
      case ThemeColorSetting.beach:
        return Color(0XFFFFF0DD);  
    }
  }

  Color get accentColor {
    switch (_colorSetting) {
      case ThemeColorSetting.blues:
        return Color(0XFF526D82);
      case ThemeColorSetting.beach:
        return Color(0XFFE2A16F);  
    }
  }

  Color get hightlightColor {
    switch (_colorSetting) {
      case ThemeColorSetting.blues:
        return Color(0XFFDDE6ED);
      case ThemeColorSetting.beach:
        return Color(0XFFD1D3D4);  
    }
  }

  Color get textColor {
    switch (_colorSetting) {
      case ThemeColorSetting.blues:
        return Color(0XFF27374D);
      case ThemeColorSetting.beach:
        return Color(0XFF86B0BD);  
    }
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
        return 20.0;
      case ThemeFontSetting.large:
        return 36.0;
    }
  }

  ThemeMode get materialThemeMode {
    return _mode == ThemeModeSetting.light
        ? ThemeMode.light
        : ThemeMode.dark;
  }
}