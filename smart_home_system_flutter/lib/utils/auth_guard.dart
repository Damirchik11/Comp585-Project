import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/auth_page.dart';
import '../widgets/loading_widget.dart';

/// Authentication guard to protect routes
/// Redirects to login page if user is not authenticated
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingWidget(message: 'Loading...'),
          );
        }

        // User is signed in
        if (snapshot.hasData && snapshot.data != null) {
          return child;
        }

        // User is not signed in - redirect to auth page
        return const AuthPage();
      },
    );
  }
}
