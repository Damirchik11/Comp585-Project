import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';
import '../widgets/app_drawer.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({Key? key}) : super(key: key);

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final List<Map<String, dynamic>> _devices = [];
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Devices'),
        titleTextStyle: TextStyle(fontSize: controller.resolvedFontSize*1.5,),
        backgroundColor: controller.accentColor,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 36, right: 36, top: 36),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanForDevices,
                  icon: Icon(Icons.search, color: controller.accentColor,),
                  label: Text('Scan for Devices', style: TextStyle(color: controller.accentColor, fontSize: controller.resolvedFontSize),),
                ),
                const SizedBox(width: 16),
                if (_isScanning) CircularProgressIndicator(color: controller.accentColor),
              ],
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? Center(child: Text('No devices found', style: TextStyle(color: controller.textColor, fontSize: controller.resolvedFontSize),))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return ListTile(
                        leading: const Icon(Icons.devices_other),
                        title: Text(device['name']),
                        subtitle: Text(device['status']),
                        trailing: Switch(
                          value: device['connected'],
                          onChanged: (value) => _toggleDevice(index, value),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _scanForDevices() {
    setState(() => _isScanning = true);
    // TODO: Implement actual device scanning
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isScanning = false;
        // Mock devices for now
        _devices.add({
          'name': 'Smart Light 1',
          'status': 'Available',
          'connected': false,
        });
      });
    });
  }

  void _toggleDevice(int index, bool value) {
    setState(() {
      _devices[index]['connected'] = value;
      _devices[index]['status'] = value ? 'Connected' : 'Disconnected';
    });
  }
}