import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum DeviceType {
  light,
  thermostat,
  lock,
  camera,
  sensor,
  outlet,
  unknown
}

enum DeviceStatus {
  available,
  connecting,
  connected,
  disconnected,
  error
}

class SmartDevice {
  final String id;
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final int? rssi; // Signal strength
  final BluetoothDevice? bluetoothDevice;
  final DateTime? lastSeen;
  final bool isPaired;
  final bool isMockDevice; // Flag to indicate simulated device
  final Map<String, dynamic>? state; // Device-specific state (brightness, temp, etc)
  
  SmartDevice({
    required this.id,
    required this.name,
    required this.type,
    this.status = DeviceStatus.available,
    this.rssi,
    this.bluetoothDevice,
    this.lastSeen,
    this.isPaired = false,
    this.isMockDevice = false,
    this.state,
  });
  
  SmartDevice copyWith({
    DeviceStatus? status,
    int? rssi,
    Map<String, dynamic>? state,
    bool? isPaired,
    bool? isMockDevice,
  }) {
    return SmartDevice(
      id: id,
      name: name,
      type: type,
      status: status ?? this.status,
      rssi: rssi ?? this.rssi,
      bluetoothDevice: bluetoothDevice,
      lastSeen: DateTime.now(),
      isPaired: isPaired ?? this.isPaired,
      isMockDevice: isMockDevice ?? this.isMockDevice,
      state: state ?? this.state,
    );
  }
}