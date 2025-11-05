import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanForDevices,
                  icon: const Icon(Icons.search),
                  label: const Text('Scan for Devices'),
                ),
                const SizedBox(width: 16),
                if (_isScanning) const CircularProgressIndicator(),
              ],
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? const Center(child: Text('No devices found'))
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