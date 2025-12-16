// lib/models/placed_device.dart
import 'package:flutter/material.dart';
import 'device.dart';

class PlacedDevice {
  final int id;
  final SmartDevice device;
  final int gridX;
  final int gridY;
  final double iconScale;
  final Map<String, dynamic> state;

  PlacedDevice({
    required this.id,
    required this.device,
    required this.gridX,
    required this.gridY,
    this.iconScale = 1.0,
    Map<String, dynamic>? state,
  }) : state = Map<String, dynamic>.from(state ?? device.state ?? {});

  PlacedDevice copyWith({
    int? id,
    SmartDevice? device,
    int? gridX,
    int? gridY,
    double? iconScale,
    Map<String, dynamic>? state,
  }) {
    return PlacedDevice(
      id: id ?? this.id,
      device: device ?? this.device,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      iconScale: iconScale ?? this.iconScale,
      state: state ?? Map<String, dynamic>.from(this.state),
    );
  }
}
