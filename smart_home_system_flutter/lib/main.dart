import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_storage_service.dart';
import 'utils/auth_guard.dart';
import 'pages/home_layout_page.dart';
import 'pages/devices_page.dart';
import 'pages/settings_page.dart';
import 'pages/tutorial_page.dart';
import 'pages/auth_page.dart';
import 'widgets/loading_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Enable Firestore offline persistence
  await FirebaseStorageService.enableOfflinePersistence();
  
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home Layout',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Start with a StreamBuilder to check auth state
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // Show loading while checking auth state
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: LoadingWidget(message: 'Checking authentication...'),
            );
          }

          // If user is signed in, show home page
          if (authSnapshot.hasData && authSnapshot.data != null) {
            return const HomeLayoutPage();
          }

          // User not signed in - show auth page
          return const AuthPage();
        },
      ),
      routes: {
        '/home': (context) => const AuthGuard(child: HomeLayoutPage()),
        '/devices': (context) => const AuthGuard(child: DevicesPage()),
        '/settings': (context) => const AuthGuard(child: SettingsPage()),
        '/tutorial': (context) => const AuthGuard(child: TutorialPage()),
        '/auth': (context) => const AuthPage(),
      },
    );
  }
}