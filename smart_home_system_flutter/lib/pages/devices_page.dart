import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Devices Page - Coming Soon')),
    );
  }
}