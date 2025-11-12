import 'package:flutter/material.dart';
import 'pages/home_layout_page.dart';
import 'pages/devices_page.dart';
import 'pages/settings_page.dart';
import 'pages/tutorial_page.dart';
import 'pages/auth_page.dart';
import 'pages/create_account.dart';

void main() => runApp(const SmartHomeApp());

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home Layout',
      theme: ThemeData(primarySwatch: Colors.blue),
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