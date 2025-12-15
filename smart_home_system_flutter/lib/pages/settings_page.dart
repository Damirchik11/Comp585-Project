import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final List<String> _profile = ['Profile Name', 'Email'];
  final List<String> _profileEdit = [CreateAccountPage().getName(), CreateAccountPage().getEmail()];
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);
    final size = controller.fontSize;

    return Scaffold(
      appBar: AppBar(title: Text('Settings'),
        titleTextStyle: TextStyle(fontSize: controller.resolvedFontSize*1.5,),
        backgroundColor: controller.accentColor,),
      drawer: const AppDrawer(),
      body: ListView(
        padding: EdgeInsetsGeometry.only(left: 36, right: 36),
        children: [
          _buildSection('', [
            ExpansionTile(
              title: Text('Profile Settings'),
              childrenPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
              children: List.generate(_profile.length, (index){
                return ListTile(
                  leading: Text(_profile[index], style: TextStyle(fontSize: controller.resolvedFontSize),),
                  title: Text(_profileEdit[index], style: TextStyle(fontSize: controller.resolvedFontSize),),
                  trailing: TextButton(onPressed: (){
                    _editProfile(index);
                  },
                  child: Text('Edit', style: TextStyle(color: controller.accentColor,fontSize: controller.resolvedFontSize*0.75),),
                  ),
                );
              })
              ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: Text('Change Password', style: TextStyle(fontSize: controller.resolvedFontSize),),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _editProfile(1);
              },
            ),
          ]),
          const Divider(),
          ListTile(
            title: Text("Theme Mode", style: TextStyle(fontSize: controller.resolvedFontSize),),
            subtitle: Text(controller.mode == ThemeModeSetting.light ? "Light" : "Dark"),
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
              selected: {controller.mode},
              onSelectionChanged: (value) {
                controller.setMode(value.first);
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: Text("Font Size", style: TextStyle(fontSize: controller.resolvedFontSize),),
            subtitle: Text(size == ThemeFontSetting.normal ? "Normal" : "Large"),
            trailing: SegmentedButton<ThemeFontSetting>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeFontSetting.normal,
                  label: Text('Normal', style: TextStyle(fontSize: controller.resolvedFontSize),),
                ),
                ButtonSegment(
                  value: ThemeFontSetting.large,
                  label: Text('Large', style: TextStyle(fontSize: controller.resolvedFontSize),),
                ),
              ],
              selected: {controller.fontSize},
              onSelectionChanged: (value) {
                controller.setFontSize(value.first);
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: Text("Color Scheme", style: TextStyle(fontSize: controller.resolvedFontSize),),
            subtitle: Text(controller.colorSetting == ThemeColorSetting.blues ? "Blues" : "Beach"),
            trailing: SegmentedButton<ThemeColorSetting>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeColorSetting.blues,
                  label: Text('Default', style: TextStyle(fontSize: controller.resolvedFontSize),),
                ),
                ButtonSegment(
                  value: ThemeColorSetting.beach,
                  label: Text('Beach Vibes', style: TextStyle(fontSize: controller.resolvedFontSize),),
                ),
              ],
              selected: {controller.colorSetting},
              onSelectionChanged: (value) {
                controller.setColor(value.first);
              },
            ),
          ),
          const Divider(),
          _buildSection('', [
            SwitchListTile(
              secondary: Icon(Icons.notifications),
              title: Text('Push Notifications', style: TextStyle(fontSize: controller.resolvedFontSize),),
              value: _notificationsEnabled,
              onChanged: (bool newValue) {
                setState(() {
                  _notificationsEnabled = newValue;
                });
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final controller = Provider.of<ThemeModeController>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: controller.resolvedFontSize,
              fontWeight: FontWeight.bold,
              color: controller.textColor,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  void _editProfile(int index){
    final profileEdit = TextEditingController(text: _profileEdit[index]);
    final controller = Provider.of<ThemeModeController>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit '),
        titleTextStyle: TextStyle(fontSize: controller.resolvedFontSize,
            fontWeight: FontWeight.bold,
            color: controller.textColor,
        ),
        content: TextField(
          controller: profileEdit,
          decoration: InputDecoration(labelText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize),),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _profileEdit[index] = profileEdit.text;
              });
              Navigator.pop(context);
            },
            child: Text('Save', style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize),),
          ),
        ],
      ),
    );
  }
}