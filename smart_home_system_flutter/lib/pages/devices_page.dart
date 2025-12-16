import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';
import '../widgets/app_drawer.dart';
import '../models/device.dart';
import '../services/bluetooth_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/platform_service.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> with TickerProviderStateMixin {
  final BluetoothService _bluetoothService = BluetoothService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final PlatformService _platformService = PlatformService();
  
  List<SmartDevice> _availableDevices = [];
  bool _isScanning = false;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initBluetooth();
  }
  
  Future<void> _initBluetooth() async {
    final hasPermissions = await _bluetoothService.requestPermissions();
    if (!hasPermissions && _platformService.isMobilePlatform) {
      _showPermissionDialog();
      return;
    }
    
    _bluetoothService.devicesStream.listen((devices) {
      if (mounted) {
        setState(() => _availableDevices = devices);
      }
    });
  }
  
  Future<void> _scanForDevices() async {
    setState(() => _isScanning = true);
    await _bluetoothService.startScan();
    await Future.delayed(const Duration(seconds: 10));
    await _bluetoothService.stopScan();
    setState(() => _isScanning = false);
  }
  
  Future<void> _connectDevice(SmartDevice device) async {
    setState(() {
      final index = _availableDevices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        _availableDevices[index] = device.copyWith(status: DeviceStatus.connecting);
      }
    });
    
    final success = await _bluetoothService.connectDevice(device);
    
    if (success) {
      final connectedDevice = device.copyWith(
        status: DeviceStatus.connected,
        isPaired: true,
      );
      // Save to Firestore - will update UI via StreamBuilder
      await _storageService.savePairedDevice(connectedDevice);
      setState(() {
        _availableDevices.removeWhere((d) => d.id == device.id);
      });
      _showSnackBar('Connected to ${device.name}', Colors.green);
    } else {
      setState(() {
        final index = _availableDevices.indexWhere((d) => d.id == device.id);
        if (index != -1) {
          _availableDevices[index] = device.copyWith(status: DeviceStatus.error);
        }
      });
      _showSnackBar('Failed to connect to ${device.name}', Colors.red);
    }
  }
  
  Future<void> _disconnectDevice(SmartDevice device) async {
    await _bluetoothService.disconnectDevice(device);
    // Remove from Firestore - will update UI via StreamBuilder
    await _storageService.removePairedDevice(device.id);
    _showSnackBar('Disconnected from ${device.name}', Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Devices'),
            if (_platformService.isDesktopPlatform) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_platformService.platformName} - Mock Mode',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Paired Devices'),
            Tab(text: 'Available Devices'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPairedDevicesTab(),
          _buildAvailableDevicesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? null : _scanForDevices,
        icon: _isScanning 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.search),
        label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
      ),
    );
  }
  
  // Real-time Firestore stream for paired devices
  Widget _buildPairedDevicesTab() {
    return StreamBuilder<List<SmartDevice>>(
      stream: _storageService.getPairedDevicesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        final pairedDevices = snapshot.data ?? [];
        
        if (pairedDevices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_other, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No paired devices', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Scan for devices to get started', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: pairedDevices.length,
          itemBuilder: (context, index) => _buildDeviceCard(pairedDevices[index], isPaired: true),
        );
      },
    );
  }
  
  Widget _buildAvailableDevicesTab() {
    if (_availableDevices.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No devices found', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            if (_platformService.isDesktopPlatform)
              const Text('Tap scan to discover simulated devices', style: TextStyle(color: Colors.grey))
            else
              const Text('Tap scan button to search', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _availableDevices.length,
      itemBuilder: (context, index) => _buildDeviceCard(_availableDevices[index]),
    );
  }
  
  Widget _buildDeviceCard(SmartDevice device, {bool isPaired = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _getDeviceIcon(device.type),
        title: Row(
          children: [
            Flexible(child: Text(device.name)),
            if (device.isMockDevice) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Text(
                  'SIM',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getStatusText(device.status)),
            if (device.rssi != null) Text('Signal: ${device.rssi} dBm', style: const TextStyle(fontSize: 12)),
            if (device.isMockDevice && _platformService.isDebugMode)
              Text('Platform: ${_platformService.platformName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        trailing: isPaired
          ? IconButton(
              icon: const Icon(Icons.bluetooth_disabled, color: Colors.red),
              onPressed: () => _disconnectDevice(device),
            )
          : ElevatedButton(
              onPressed: device.status == DeviceStatus.connecting 
                ? null 
                : () => _connectDevice(device),
              child: const Text('Connect'),
            ),
      ),
    );
  }
  
  Icon _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.light: return const Icon(Icons.lightbulb);
      case DeviceType.thermostat: return const Icon(Icons.thermostat);
      case DeviceType.lock: return const Icon(Icons.lock);
      case DeviceType.camera: return const Icon(Icons.camera);
      case DeviceType.sensor: return const Icon(Icons.sensors);
      case DeviceType.outlet: return const Icon(Icons.power);
      default: return const Icon(Icons.devices_other);
    }
  }
  
  String _getStatusText(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.available: return 'Available';
      case DeviceStatus.connecting: return 'Connecting...';
      case DeviceStatus.connected: return 'Connected';
      case DeviceStatus.disconnected: return 'Disconnected';
      case DeviceStatus.error: return 'Connection failed';
    }
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text('Bluetooth and location permissions are required to scan for devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}