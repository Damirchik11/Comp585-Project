import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/device.dart';
import 'dart:io';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();
  
  final StreamController<List<SmartDevice>> _devicesController = 
    StreamController<List<SmartDevice>>.broadcast();
  
  Stream<List<SmartDevice>> get devicesStream => _devicesController.stream;
  
  final List<SmartDevice> _discoveredDevices = [];
  StreamSubscription? _scanSubscription;
  
  Future<bool> requestPermissions() async {
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
  
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }
  
  Future<bool> connectDevice(SmartDevice device) async {
    try {
      await device.bluetoothDevice?.connect(timeout: Duration(seconds: 15));
      await device.bluetoothDevice?.discoverServices();
      return true;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }
  
  Future<void> disconnectDevice(SmartDevice device) async {
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
    _devicesController.close();
  }
}