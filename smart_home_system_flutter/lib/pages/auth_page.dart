import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';
import 'create_account.dart';



class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        titleTextStyle: TextStyle(color: controller.hightlightColor, fontSize: controller.resolvedFontSize),
        backgroundColor: controller.accentColor,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_outlined, size: 80),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      backgroundColor: controller.accentColor,
                    ),
                    child: Text('Login', style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize))
                  ),
                  TextButton(
                    child: Text('Need an account? Sign up', style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize*0.75),),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/createAcct');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (CreateAccountPage().getEmail() == _emailController.text && CreateAccountPage().getPass() == _passwordController.text) {
      Navigator.pushReplacementNamed(context, '/layout');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}