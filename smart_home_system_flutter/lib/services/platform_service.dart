import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service for detecting platform capabilities and features
class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();
  
  /// Check if running on a mobile platform (Android or iOS)
  bool get isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
  
  /// Check if running on a desktop platform (Windows, macOS, or Linux)
  bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
  
  /// Check if running on Windows
  bool get isWindows {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }
  
  /// Check if running on macOS
  bool get isMacOS {
    if (kIsWeb) return false;
    return Platform.isMacOS;
  }
  
  /// Check if running on Linux
  bool get isLinux {
    if (kIsWeb) return false;
    return Platform.isLinux;
  }
  
  /// Check if running on Android
  bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }
  
  /// Check if running on iOS
  bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }
  
  /// Check if running in a web browser
  bool get isWeb => kIsWeb;
  
  /// Check if the platform supports real Bluetooth
  bool get supportsRealBluetooth {
    return isMobilePlatform;
  }
  
  /// Get platform name as a string
  String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
  
  /// Check if running in debug mode
  bool get isDebugMode => kDebugMode;
  
  /// Check if running in release mode
  bool get isReleaseMode => kReleaseMode;
  
  /// Check if running in profile mode
  bool get isProfileMode => kProfileMode;
}
