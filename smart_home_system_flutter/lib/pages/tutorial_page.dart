import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Tutorial Page - Coming Soon')),
    );
  }
}