import 'package:flutter/material.dart';
// Moving the Room model to its own file for better organization
// Room model expressed in grid units with id to identify movable items
class Room {
  final int id;
  final int gridX;
  final int gridY;
  final int gridW;
  final int gridH;
  final Color color;
  final bool isCircle;

  Room({
    required this.id,
    required this.gridX,
    required this.gridY,
    required this.gridW,
    required this.gridH,
    required this.color,
    this.isCircle = false,
  });

  Room copyWith({int? id, int? gridX, int? gridY, int? gridW, int? gridH, Color? color, bool? isCircle}) {
    return Room(
      id: id ?? this.id,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      gridW: gridW ?? this.gridW,
      gridH: gridH ?? this.gridH,
      color: color ?? this.color,
      isCircle: isCircle ?? this.isCircle,
    );
  }
}

// Moved over from main.dart to keep related code together
class GridPoint {
  final int x;
  final int y;
  GridPoint(this.x, this.y);
}