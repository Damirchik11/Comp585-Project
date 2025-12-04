import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/device.dart';
import 'platform_service.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();
  
  // Enable mock devices for testing on ANY platform (including Android emulator)
  static const bool enableMockDevicesForTesting = true;
  
  final PlatformService _platformService = PlatformService();
  final StreamController<List<SmartDevice>> _devicesController = 
    StreamController<List<SmartDevice>>.broadcast();
  
  Stream<List<SmartDevice>> get devicesStream => _devicesController.stream;
  
  final List<SmartDevice> _discoveredDevices = [];
  StreamSubscription? _scanSubscription;
  
  // Mock device data for testing
  final List<SmartDevice> _mockDevices = [];
  Timer? _mockScanTimer;
  final Random _random = Random();
  
  // Check if we should use mock devices (desktop OR testing enabled)
  bool get _useMockDevices => _platformService.isDesktopPlatform || enableMockDevicesForTesting;
  
  /// Initialize mock devices
  void _initMockDevices() {
    _mockDevices.clear();
    _mockDevices.addAll([
      SmartDevice(
        id: 'mock_light_001',
        name: 'Living Room Light',
        type: DeviceType.light,
        rssi: -45 - _random.nextInt(20),
        isMockDevice: true,
        state: {'brightness': 80, 'on': true},
      ),
      SmartDevice(
        id: 'mock_light_002',
        name: 'Bedroom Light',
        type: DeviceType.light,
        rssi: -55 - _random.nextInt(20),
        isMockDevice: true,
        state: {'brightness': 60, 'on': false},
      ),
      SmartDevice(
        id: 'mock_thermostat_001',
        name: 'Smart Thermostat',
        type: DeviceType.thermostat,
        rssi: -40 - _random.nextInt(15),
        isMockDevice: true,
        state: {'temperature': 72, 'mode': 'heat'},
      ),
      SmartDevice(
        id: 'mock_lock_001',
        name: 'Front Door Lock',
        type: DeviceType.lock,
        rssi: -50 - _random.nextInt(20),
        isMockDevice: true,
        state: {'locked': true},
      ),
      SmartDevice(
        id: 'mock_camera_001',
        name: 'Security Camera',
        type: DeviceType.camera,
        rssi: -60 - _random.nextInt(25),
        isMockDevice: true,
        state: {'recording': true, 'motion_detected': false},
      ),
      SmartDevice(
        id: 'mock_sensor_001',
        name: 'Motion Sensor',
        type: DeviceType.sensor,
        rssi: -65 - _random.nextInt(20),
        isMockDevice: true,
        state: {'motion': false, 'battery': 85},
      ),
      SmartDevice(
        id: 'mock_outlet_001',
        name: 'Smart Outlet',
        type: DeviceType.outlet,
        rssi: -48 - _random.nextInt(15),
        isMockDevice: true,
        state: {'on': true, 'power': 120},
      ),
      SmartDevice(
        id: 'mock_sensor_002',
        name: 'Kitchen Temp Sensor',
        type: DeviceType.sensor,
        rssi: -70 - _random.nextInt(20),
        isMockDevice: true,
        state: {'temperature': 68, 'humidity': 45},
      ),
    ]);
  }
  
  Future<bool> requestPermissions() async {
    // Skip permissions if using mock devices
    if (_useMockDevices) {
      return true;
    }
    
    // Mobile platforms: request Bluetooth permissions
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    }
    return true;
  }
  
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    _discoveredDevices.clear();
    
    // Use mock device scanning if enabled
    if (_useMockDevices) {
      _startMockScan(timeout);
      return;
    }
    
    // Real Bluetooth scanning on mobile
    await FlutterBluePlus.startScan(timeout: timeout);
    
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        final existingIndex = _discoveredDevices.indexWhere(
          (device) => device.id == result.device.id.toString()
        );
        
        final smartDevice = SmartDevice(
          id: result.device.id.toString(),
          name: result.device.name.isEmpty ? 'Unknown Device' : result.device.name,
          type: _identifyDeviceType(result.device.name),
          rssi: result.rssi,
          bluetoothDevice: result.device,
          lastSeen: DateTime.now(),
          isMockDevice: false,
        );
        
        if (existingIndex != -1) {
          _discoveredDevices[existingIndex] = smartDevice;
        } else {
          _discoveredDevices.add(smartDevice);
        }
      }
      _devicesController.add(List.from(_discoveredDevices));
    });
  }
  
  /// Simulate device scanning
  void _startMockScan(Duration timeout) {
    _initMockDevices();
    
    // Simulate gradual device discovery
    int devicesFound = 0;
    _mockScanTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (devicesFound < _mockDevices.length) {
        _discoveredDevices.add(_mockDevices[devicesFound]);
        devicesFound++;
        _devicesController.add(List.from(_discoveredDevices));
      } else {
        timer.cancel();
      }
    });
    
    // Stop scan after timeout
    Future.delayed(timeout, () {
      _mockScanTimer?.cancel();
    });
  }
  
  Future<void> stopScan() async {
    if (_useMockDevices) {
      _mockScanTimer?.cancel();
      return;
    }
    
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }
  
  Future<bool> connectDevice(SmartDevice device) async {
    // Mock device connection
    if (_useMockDevices || device.isMockDevice) {
      // Simulate connection delay
      await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1500)));
      
      // 95% success rate for mock connections
      return _random.nextDouble() > 0.05;
    }
    
    // Real Bluetooth connection on mobile
    try {
      await device.bluetoothDevice?.connect(timeout: const Duration(seconds: 15));
      await device.bluetoothDevice?.discoverServices();
      return true;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }
  
  Future<void> disconnectDevice(SmartDevice device) async {
    // Mock device disconnection
    if (_useMockDevices || device.isMockDevice) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }
    
    // Real Bluetooth disconnection on mobile
    await device.bluetoothDevice?.disconnect();
  }
  
  DeviceType _identifyDeviceType(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('light') || lowerName.contains('bulb')) return DeviceType.light;
    if (lowerName.contains('thermo') || lowerName.contains('temp')) return DeviceType.thermostat;
    if (lowerName.contains('lock')) return DeviceType.lock;
    if (lowerName.contains('camera')) return DeviceType.camera;
    if (lowerName.contains('sensor')) return DeviceType.sensor;
    if (lowerName.contains('outlet') || lowerName.contains('plug')) return DeviceType.outlet;
    return DeviceType.unknown;
  }
  
  void dispose() {
    _scanSubscription?.cancel();
    _mockScanTimer?.cancel();
    _devicesController.close();
  }
}