import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: ListView(
        children: [
          _buildSection('Profile', [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to profile settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to change password
              },
            ),
          ]),
          const Divider(),
          _buildSection('Appearance', [
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (value) {
                setState(() => _darkMode = value);
                // TODO: Implement theme switching
              },
            ),
          ]),
          const Divider(),
          _buildSection('Notifications', [
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('Push Notifications'),
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}