import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/auth_guard.dart';
import 'pages/home_layout_page.dart';
import 'pages/devices_page.dart';
import 'pages/settings_page.dart';
import 'pages/tutorial_page.dart';
import 'pages/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home Layout',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGuard(child: HomeLayoutPage()),
        '/devices': (context) => const AuthGuard(child: DevicesPage()),
        '/settings': (context) => const AuthGuard(child: SettingsPage()),
        '/tutorial': (context) => const AuthGuard(child: TutorialPage()),
        '/auth': (context) => const AuthPage(),
      },
    );
  }
}