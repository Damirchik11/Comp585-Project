import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/device.dart';

class StorageService {
  static const String _pairedDevicesKey = 'paired_devices';
  
  Future<void> savePairedDevice(SmartDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final devices = await getPairedDevices();
    
    devices.removeWhere((d) => d.id == device.id);
    devices.add(device);
    
    final jsonList = devices.map((d) => {
      'id': d.id,
      'name': d.name,
      'type': d.type.toString(),
      'isMockDevice': d.isMockDevice,
    }).toList();
    
    await prefs.setString(_pairedDevicesKey, jsonEncode(jsonList));
  }
  
  Future<List<SmartDevice>> getPairedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pairedDevicesKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => SmartDevice(
      id: json['id'],
      name: json['name'],
      type: DeviceType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => DeviceType.unknown,
      ),
      isPaired: true,
      isMockDevice: json['isMockDevice'] ?? false,
    )).toList();
  }
  
  Future<void> removePairedDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final devices = await getPairedDevices();
    devices.removeWhere((d) => d.id == deviceId);
    
    final jsonList = devices.map((d) => {
      'id': d.id,
      'name': d.name,
      'type': d.type.toString(),
      'isMockDevice': d.isMockDevice,
    }).toList();
    
    await prefs.setString(_pairedDevicesKey, jsonEncode(jsonList));
  }
}