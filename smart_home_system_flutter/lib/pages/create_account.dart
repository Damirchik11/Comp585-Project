import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';

List<Map<String, dynamic>> entries =[];

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAcctState();

  String getName() {
    return entries[0]["name"];
  }

  String getEmail(){
    return entries[0]["email"];
  }

  String getPass() {
    return entries[0]["password"];
  }

}


class _CreateAcctState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordCheckController = TextEditingController();
  

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
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
                    controller: _nameController,
                    style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize),
                    decoration: const InputDecoration(
                      labelText: 'Profile Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _passwordController,
                    style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize),
                    decoration: const InputDecoration(
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
                  TextFormField(
                    controller: _passwordCheckController,
                    style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize),
                    decoration: const InputDecoration(
                      labelText: 'Reenter Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (value != _passwordController.text) return 'Passwords do not match';
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
                    child: Text('Create Account', style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize),)
                  ),
                  TextButton(
                    child: Text('Already have an account? Login', style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize*0.75),),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/auth');
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

  void saveProfile() {
    entries.add({
      "name": _nameController.text,
      "email": _emailController.text,
      "password": _passwordController.text,
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      saveProfile();
      Navigator.pushReplacementNamed(context, '/layout');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}