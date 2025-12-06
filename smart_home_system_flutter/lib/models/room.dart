// lib/models/room.dart
import 'package:flutter/material.dart';

class Room {
  final int id;
  final int gridX;
  final int gridY;
  final int gridW;
  final int gridH;
  final Color color;
  final bool isCircle;
  final String label;

  Room({
    required this.id,
    required this.gridX,
    required this.gridY,
    required this.gridW,
    required this.gridH,
    required this.color,
    this.isCircle = false,
    this.label = '',
  });

  Room copyWith({
    int? id,
    int? gridX,
    int? gridY,
    int? gridW,
    int? gridH,
    Color? color,
    bool? isCircle,
    String? label,
  }) {
    return Room(
      id: id ?? this.id,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      gridW: gridW ?? this.gridW,
      gridH: gridH ?? this.gridH,
      color: color ?? this.color,
      isCircle: isCircle ?? this.isCircle,
      label: label ?? this.label,
    );
  }

  // Optional: helpers for JSON serialization if you want to save/load layouts
  Map<String, dynamic> toJson() => {
        'id': id,
        'gridX': gridX,
        'gridY': gridY,
        'gridW': gridW,
        'gridH': gridH,
        'color': color.value,
        'isCircle': isCircle,
        'label': label,
      };

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      gridX: json['gridX'] as int,
      gridY: json['gridY'] as int,
      gridW: json['gridW'] as int,
      gridH: json['gridH'] as int,
      color: Color(json['color'] as int),
      isCircle: json['isCircle'] as bool? ?? false,
      label: json['label'] as String? ?? '',
    );
  }
}