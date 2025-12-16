import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/theme_mode_setting.dart';


class ThemeModeController extends ChangeNotifier {
  //Theme
  ThemeModeSetting _mode = ThemeModeSetting.light;
  ThemeModeSetting get mode => _mode;

  //Colors
  ThemeColorSetting _colorSetting = ThemeColorSetting.blues;
  ThemeColorSetting get colorSetting => _colorSetting;

  //Font
  ThemeFontSetting _fontSize = ThemeFontSetting.normal;
  ThemeFontSetting get fontSize => _fontSize;

  User? _currentUser;
  
  ThemeModeController() {
    _initAuthListener();
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadSettings();
      } else {
        // Reset to defaults on logout if desired, or keep last state
        notifyListeners();
      }
    });
  }

  Future<void> _loadSettings() async {
    if (_currentUser == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('settings')) {
          final settings = data['settings'] as Map<String, dynamic>;
          
          // Load Theme
          if (settings.containsKey('themeMode')) {
            _mode = settings['themeMode'] == 'dark' ? ThemeModeSetting.dark : ThemeModeSetting.light;
          }
          
          // Load Color Scheme
          if (settings.containsKey('colorScheme')) {
            _colorSetting = settings['colorScheme'] == 'beach' ? ThemeColorSetting.beach : ThemeColorSetting.blues;
          }
           else if (settings.containsKey('colorSetting')) { // Legacy/Typo support
            _colorSetting = settings['colorSetting'] == 'beach' ? ThemeColorSetting.beach : ThemeColorSetting.blues;
          }

          // Load Font Size
          if (settings.containsKey('fontSize')) {
            _fontSize = settings['fontSize'] == 'large' ? ThemeFontSetting.large : ThemeFontSetting.normal;
          }
          
          notifyListeners();
        }
      }
    } catch (e) {
      print("Error loading settings: $e");
    }
  }

  Future<void> _saveSettings() async {
    if (_currentUser == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
        'settings': {
          'themeMode': _mode == ThemeModeSetting.dark ? 'dark' : 'light',
          'colorScheme': _colorSetting == ThemeColorSetting.beach ? 'beach' : 'blues',
          'fontSize': _fontSize == ThemeFontSetting.large ? 'large' : 'normal',
        }
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving settings: $e");
    }
  }

  void setMode(ThemeModeSetting newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      _saveSettings();
      notifyListeners();
    }
  }

  void setColor(ThemeColorSetting newColor) {
    if (_colorSetting != newColor) {
      _colorSetting = newColor;
      _saveSettings();
      notifyListeners();
    }
  }

  void setFontSize(ThemeFontSetting newSize) {
    if (_fontSize != newSize) {
      _fontSize = newSize;
      _saveSettings();
      notifyListeners();
    }
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