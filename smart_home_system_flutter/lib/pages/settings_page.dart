import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

enum ThemeModeSetting { light, dark }
enum ThemeFontSetting { normal, large }

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // bool _darkMode = false;
  ThemeModeSetting _mode = ThemeModeSetting.light;
  ThemeFontSetting _fontSize = ThemeFontSetting.normal;
  final List<String> _profile = ['Profile Name', 'Email'];
  final List<String> _profileEdit = ['Bobby B', 'me@email.com'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: ListView(
        children: [
          _buildSection('Profile', [
            ExpansionTile(
              title: Text('Profile Settings'),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              children: List.generate(_profile.length, (index){
                return ListTile(
                  leading: Text(_profile[index]),
                  title: Text(_profileEdit[index]),
                  trailing: TextButton(onPressed: (){
                    _editProfile(index);
                  },
                  child: const Text('Edit'),
                  ),
                );
              })
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
          ListTile(
            title: Text("Theme Mode"),
            subtitle: Text(_mode == ThemeModeSetting.light ? "Light" : "Dark"),
            trailing: SegmentedButton<ThemeModeSetting>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeModeSetting.light,
                  label: Text(''),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeModeSetting.dark,
                  label: Text(''),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) {
                setState(() => _mode = value.first);
                // TODO: Implement theme switching
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: Text("Font Size"),
            subtitle: Text(_fontSize == ThemeFontSetting.normal ? "Normal" : "Large"),
            trailing: SegmentedButton<ThemeFontSetting>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeFontSetting.normal,
                  label: Text('Normal'),
                ),
                ButtonSegment(
                  value: ThemeFontSetting.large,
                  label: Text('Large'),
                ),
              ],
              selected: {_fontSize},
              onSelectionChanged: (value) {
                setState(() => _fontSize = value.first);
                // TODO: Implement theme switching
              },
            ),
          ),
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

  void _editProfile(int index){
    final controller = TextEditingController(text: _profileEdit[index]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit value'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Value'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _profileEdit[index] = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}