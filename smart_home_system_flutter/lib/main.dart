import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_storage_service.dart';
import 'utils/auth_guard.dart';
import 'package:provider/provider.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';
import 'pages/home_layout_page.dart';
import 'pages/devices_page.dart';
import 'pages/settings_page.dart';
import 'pages/tutorial_page.dart';
import 'pages/auth_page.dart';
import 'widgets/loading_widget.dart';
import 'pages/create_account.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Enable Firestore offline persistence
  await FirebaseStorageService.enableOfflinePersistence();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeModeController(),
      child: const SmartHomeApp(),
    ),
  );
}



class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);
    final baseLight = ThemeData.light();
    final baseDark = ThemeData.dark();

    return MaterialApp(
      title: 'Smart Home Layout',
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
      theme: baseLight.copyWith(
        textTheme: baseLight.textTheme.copyWith(
          bodyMedium: baseLight.textTheme.bodyMedium?.copyWith(
            fontSize: controller.resolvedFontSize,
            color: controller.textColor)),
        scaffoldBackgroundColor: controller.backgroundColor,
      ),
      darkTheme: baseDark.copyWith(
        textTheme: baseDark.textTheme.copyWith(
          bodyMedium: baseDark.textTheme.bodyMedium?.copyWith(
            fontSize: controller.resolvedFontSize,
            color: controller.hightlightColor,)),
        scaffoldBackgroundColor: controller.textColor,
      ),
      themeMode: controller.materialThemeMode,
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const AuthGuard(child: HomeLayoutPage()),
        '/layout': (context) => const HomeLayoutPage(),
        '/devices': (context) => const AuthGuard(child: DevicesPage()),
        '/settings': (context) => const AuthGuard(child: SettingsPage()),
        '/tutorial': (context) => const AuthGuard(child: TutorialPage()),
        '/createAcct': (context) => const CreateAccountPage(),
      },
    );
  }
}

