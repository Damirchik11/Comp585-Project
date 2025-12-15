import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';

// Created a reusable AppDrawer widget for navigation
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: controller.accentColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.home_outlined, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'Smart Home',
                  style: TextStyle(fontSize: controller.resolvedFontSize*1.5),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.grid_on),
            title: Text('Room Layout', style: TextStyle(fontSize: controller.resolvedFontSize)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/layout');
            },
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: Text('Devices', style: TextStyle(fontSize: controller.resolvedFontSize)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/devices');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text('Settings', style: TextStyle(fontSize: controller.resolvedFontSize)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text('Tutorial', style: TextStyle(fontSize: controller.resolvedFontSize)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/tutorial');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
    );
  }
}