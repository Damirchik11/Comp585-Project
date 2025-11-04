import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Settings Page - Coming Soon')),
    );
  }
}