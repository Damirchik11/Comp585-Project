import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home_system/models/font_size_setting.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';
import '../models/theme_mode_setting.dart';
import '../widgets/app_drawer.dart';
import 'create_account.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ThemeModeSetting _mode = ThemeModeSetting.light;
  // ThemeFontSetting _fontSize = ThemeFontSetting.normal;
  final List<String> _profile = ['Profile Name', 'Email'];
  final List<String> _profileEdit = [CreateAccountPage().getName(), CreateAccountPage().getEmail()];

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeModeController>(context);
    final settings = Provider.of<ThemeModeController>(context);
    final size = settings.resolvedFontSize;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const AppDrawer(),
      body: ListView(
        children: [
          _buildSection('Profile', [
            ExpansionTile(
              title: Text('Profile Settings'),
              childrenPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
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
            subtitle: Text(themeController.mode == ThemeModeSetting.light ? "Light" : "Dark"),
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
              selected: {themeController.mode},
              onSelectionChanged: (value) {
                themeController.setMode(value.first);
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: Text("Font Size"),
            subtitle: Text(size == ThemeFontSetting.normal ? "Normal" : "Large"),
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
              selected: { settings.fontSize },
              onSelectionChanged: (value) {
                settings.setFontSize(value.first);
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