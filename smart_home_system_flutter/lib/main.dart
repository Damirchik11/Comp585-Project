import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';
import 'pages/home_layout_page.dart';
import 'pages/devices_page.dart';
import 'pages/settings_page.dart';
import 'pages/tutorial_page.dart';
import 'pages/auth_page.dart';
import 'pages/create_account.dart';




void main() => runApp(ChangeNotifierProvider(
      create: (_) => ThemeModeController(),
      child:const SmartHomeApp()));

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);

    return MaterialApp(
      title: 'Smart Home Layout',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: controller.materialThemeMode,
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthPage(),
        '/layout': (context) => const HomeLayoutPage(),
        '/devices': (context) => const DevicesPage(),
        '/settings': (context) => const SettingsPage(),
        '/tutorial': (context) => const TutorialPage(),
        '/createAcct': (context) => const CreateAccountPage(),
        
      },
    );
  }
}

