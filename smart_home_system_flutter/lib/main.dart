import 'package:flutter/material.dart';

void main() => runApp(const SmartHomeApp());

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home Layout',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeLayoutPage(),
    );
  }
}

class HomeLayoutPage extends StatefulWidget {
  const HomeLayoutPage({Key? key}) : super(key: key);

  @override
  State<HomeLayoutPage> createState() => _HomeLayoutPageState();
}

// Simple Room model expressed in grid units
class Room {
  final int gridX;
  final int gridY;
  final int gridW;
  final int gridH;
  final Color color;
  final bool isCircle;

  Room({
    required this.gridX,
    required this.gridY,
    required this.gridW,
    required this.gridH,
    required this.color,
    this.isCircle = false,
  });

  Room copyWith({int? gridX, int? gridY}) {
    return Room(
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      gridW: gridW,
      gridH: gridH,
      color: color,
      isCircle: isCircle,
    );
  }
}

// Small helper for BFS points
class _GridPoint {
  final int x;
  final int y;
  _GridPoint(this.x, this.y);
}

class _HomeLayoutPageState extends State<HomeLayoutPage> {
  final int cellSize = 40; // pixels per grid cell
  final List<Room> _placedRooms = [];
  final GlobalKey _canvasKey = GlobalKey(); // used to convert global->local coordinates

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Floor Plan Editor')),
      body: Row(
        children: [
          // Sidebar toolbox
          Container(
            width: 120,
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                _buildDraggableRoom('Square', Colors.blue, 2, 2),
                const SizedBox(height: 18),
                _buildDraggableRoom('Rectangle', Colors.green, 3, 2),
                const SizedBox(height: 18),
                _buildDraggableRoom('Circle', Colors.orange, 2, 2, isCircle: true),
              ],
            ),
          ),

          // Canvas
          Expanded(
            child: Container(
              key: _canvasKey,
              color: Colors.grey[100],
              child: Stack(
                children: [
                  // grid background
                  CustomPaint(
                    size: Size.infinite,
                    painter: GridPainter(cellSize: cellSize),
                  ),

                  // placed rooms
                  ..._placedRooms.map((r) {
                    return Positioned(
                      left: r.gridX * cellSize.toDouble(),
                      top: r.gridY * cellSize.toDouble(),
                      child: r.isCircle
                          ? Container(
                              width: r.gridW * cellSize.toDouble(),
                              height: r.gridH * cellSize.toDouble(),
                              decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
                            )
                          : Container(
                              width: r.gridW * cellSize.toDouble(),
                              height: r.gridH * cellSize.toDouble(),
                              color: r.color,
                            ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableRoom(String label, Color color, int gridW, int gridH, {bool isCircle = false}) {
    final double px = gridW * cellSize.toDouble();
    final double py = gridH * cellSize.toDouble();

    return Draggable<Room>(
      data: Room(gridX: 0, gridY: 0, gridW: gridW, gridH: gridH, color: color, isCircle: isCircle),
      feedback: Material(
        type: MaterialType.transparency,
        child: Container(
          width: px,
          height: py,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          ),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Container(width: px / 2, height: py / 2, color: color),
      ),
      child: Column(
        children: [
          Container(
            width: px / 2,
            height: py / 2,
            decoration: BoxDecoration(color: color, shape: isCircle ? BoxShape.circle : BoxShape.rectangle),
          ),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
      onDragEnd: (details) {
        // Convert global drop point to local coordinates within the canvas
        final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
        if (canvasBox == null) return; // safety

        final local = canvasBox.globalToLocal(details.offset);

        final int maxCols = (canvasBox.size.width / cellSize).floor();
        final int maxRows = (canvasBox.size.height / cellSize).floor();

        // initial snapped grid coords
        int gridX = (local.dx / cellSize).floor();
        int gridY = (local.dy / cellSize).floor();

        // clamp to valid start area (so width/height fits)
        final int maxStartX = (maxCols - gridW) >= 0 ? (maxCols - gridW) : 0;
        final int maxStartY = (maxRows - gridH) >= 0 ? (maxRows - gridH) : 0;
        if (gridX < 0) gridX = 0;
        if (gridY < 0) gridY = 0;
        if (gridX > maxStartX) gridX = maxStartX;
        if (gridY > maxStartY) gridY = maxStartY;

        Room newRoom = Room(gridX: gridX, gridY: gridY, gridW: gridW, gridH: gridH, color: color, isCircle: isCircle);

        // find nearest available position using a grid-aware search
        final fitted = _fitRoom(newRoom, maxCols, maxRows);

        setState(() {
          _placedRooms.add(fitted);
        });
      },
    );
  }

  // Returns a Room placed at the nearest available grid cell within bounds
  Room _fitRoom(Room room, int maxCols, int maxRows) {
    bool overlaps(Room a, Room b) {
      return !(a.gridX + a.gridW <= b.gridX ||
          b.gridX + b.gridW <= a.gridX ||
          a.gridY + a.gridH <= b.gridY ||
          b.gridY + b.gridH <= a.gridY);
    }

    bool fits(Room r) {
      if (r.gridX < 0 || r.gridY < 0) return false;
      if (r.gridX + r.gridW > maxCols) return false;
      if (r.gridY + r.gridH > maxRows) return false;
      for (var placed in _placedRooms) {
        if (overlaps(r, placed)) return false;
      }
      return true;
    }

    // If initial position fits, return it
    if (fits(room)) return room;

    // BFS outward from the initial grid position
    final startX = room.gridX.clamp(0, (maxCols - room.gridW) >= 0 ? (maxCols - room.gridW) : 0);
    final startY = room.gridY.clamp(0, (maxRows - room.gridH) >= 0 ? (maxRows - room.gridH) : 0);

    final queue = <_GridPoint>[_GridPoint(startX, startY)];
    final visited = <String>{'${startX}_${startY}'};
    final directions = [_GridPoint(1, 0), _GridPoint(0, 1), _GridPoint(-1, 0), _GridPoint(0, -1)];

    while (queue.isNotEmpty) {
      final p = queue.removeAt(0);
      final candidate = Room(gridX: p.x, gridY: p.y, gridW: room.gridW, gridH: room.gridH, color: room.color, isCircle: room.isCircle);
      if (fits(candidate)) return candidate;

      for (var d in directions) {
        final nx = p.x + d.x;
        final ny = p.y + d.y;
        // check bounding box validity for starting position
        if (nx < 0 || ny < 0) continue;
        if (nx + room.gridW > maxCols) continue;
        if (ny + room.gridH > maxRows) continue;
        final key = '${nx}_$ny';
        if (visited.contains(key)) continue;
        visited.add(key);
        queue.add(_GridPoint(nx, ny));
      }
    }

    // fallback if nothing found: place at (0,0)
    return Room(gridX: 0, gridY: 0, gridW: room.gridW, gridH: room.gridH, color: room.color, isCircle: room.isCircle);
  }
}

// Simple grid painter
class GridPainter extends CustomPainter {
  final int cellSize;
  GridPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => old.cellSize != cellSize;
}
