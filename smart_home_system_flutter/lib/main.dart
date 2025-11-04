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

// ---- HomeLayoutPage (main editor screen) ----
class HomeLayoutPage extends StatefulWidget {
  const HomeLayoutPage({Key? key}) : super(key: key);

  @override
  State<HomeLayoutPage> createState() => _HomeLayoutPageState();
}

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

class _GridPoint {
  final int x;
  final int y;
  _GridPoint(this.x, this.y);
}

class _HomeLayoutPageState extends State<HomeLayoutPage> {
  final int cellSize = 40; // pixels per grid cell
  final List<Room> _placedRooms = [];
  final GlobalKey _canvasKey = GlobalKey(); // used to convert global->local coordinates
  int _nextRoomId = 1;

  // track moving room id while the user drags an already placed room
  int? _movingRoomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Floor Plan Editor')),
      body: Column(
        children: [
          // Top toolbox / draggable icons row
          Container(
            height: 120,
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDraggableRoom('Square', Colors.blue, 2, 2),
                const SizedBox(width: 18),
                _buildDraggableRoom('Rectangle', Colors.green, 3, 2),
                const SizedBox(width: 18),
                _buildDraggableRoom('Circle', Colors.orange, 2, 2, isCircle: true),
                const SizedBox(width: 18),
                // you can add more toolbox items here
                Expanded(child: Container()), // pushes toolbox items to the left
              ],
            ),
          ),

          // Canvas area (fills remaining vertical space)
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: LayoutBuilder(builder: (context, constraints) {
                return Container(
                  key: _canvasKey,
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    children: [
                      // grid background
                      CustomPaint(
                        size: Size.infinite,
                        painter: GridPainter(cellSize: cellSize),
                      ),

                      // placed rooms (now movable)
                      ..._placedRooms.map((r) {
                        return Positioned(
                          left: r.gridX * cellSize.toDouble(),
                          top: r.gridY * cellSize.toDouble(),
                          child: GestureDetector(
                            onPanStart: (details) {
                              // start moving this room
                              _movingRoomId = r.id;
                            },
                            onPanUpdate: (details) {
                              // while dragging, update the room position snapped to grid
                              final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                              if (canvasBox == null) return;

                              final local = canvasBox.globalToLocal(details.globalPosition);

                              final int maxCols = (canvasBox.size.width / cellSize).floor();
                              final int maxRows = (canvasBox.size.height / cellSize).floor();

                              int gridX = (local.dx / cellSize).floor();
                              int gridY = (local.dy / cellSize).floor();

                              // clamp
                              final int maxStartX = (maxCols - r.gridW) >= 0 ? (maxCols - r.gridW) : 0;
                              final int maxStartY = (maxRows - r.gridH) >= 0 ? (maxRows - r.gridH) : 0;
                              if (gridX < 0) gridX = 0;
                              if (gridY < 0) gridY = 0;
                              if (gridX > maxStartX) gridX = maxStartX;
                              if (gridY > maxStartY) gridY = maxStartY;

                              // update the room in the placed list (live preview while dragging)
                              setState(() {
                                final idx = _placedRooms.indexWhere((p) => p.id == r.id);
                                if (idx != -1) {
                                  _placedRooms[idx] = _placedRooms[idx].copyWith(gridX: gridX, gridY: gridY);
                                }
                              });
                            },
                            onPanEnd: (details) {
                              // on end, fit the room into the nearest available spot (avoid overlaps),
                              // ignoring itself when checking collisions.
                              final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                              if (canvasBox == null) {
                                _movingRoomId = null;
                                return;
                              }

                              final int maxCols = (canvasBox.size.width / cellSize).floor();
                              final int maxRows = (canvasBox.size.height / cellSize).floor();

                              final idx = _placedRooms.indexWhere((p) => p.id == r.id);
                              if (idx != -1) {
                                final current = _placedRooms[idx];
                                final fitted = _fitRoom(
                                  current,
                                  maxCols,
                                  maxRows,
                                  ignoreId: current.id,
                                );
                                setState(() {
                                  _placedRooms[idx] = fitted;
                                });
                              }

                              _movingRoomId = null;
                            },
                            child: r.isCircle
                                ? Container(
                                    width: r.gridW * cellSize.toDouble(),
                                    height: r.gridH * cellSize.toDouble(),
                                    decoration: BoxDecoration(
                                      color: r.color, 
                                      shape: BoxShape.circle,
                                      // Add visual feedback when moving
                                      border: _movingRoomId == r.id 
                                        ? Border.all(color: Colors.white, width: 3)
                                        : null,
                                    ),
                                  )
                                : Container(
                                    width: r.gridW * cellSize.toDouble(),
                                    height: r.gridH * cellSize.toDouble(),
                                    decoration: BoxDecoration(
                                      color: r.color,
                                      // Add visual feedback when moving
                                      border: _movingRoomId == r.id
                                        ? Border.all(color: Colors.white, width: 3)
                                        : null,
                                    ),
                                  ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Top toolbox draggable builder (unchanged mostly, now used in a Row)
  Widget _buildDraggableRoom(String label, Color color, int gridW, int gridH, {bool isCircle = false}) {
    final double px = gridW * cellSize.toDouble();
    final double py = gridH * cellSize.toDouble();

    return Draggable<Room>(
      data: Room(id: -1, gridX: 0, gridY: 0, gridW: gridW, gridH: gridH, color: color, isCircle: isCircle),
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

        // create new room with unique id
        final newRoom = Room(
          id: _nextRoomId++,
          gridX: gridX,
          gridY: gridY,
          gridW: gridW,
          gridH: gridH,
          color: color,
          isCircle: isCircle,
        );

        // find nearest available position using a grid-aware search
        final fitted = _fitRoom(newRoom, maxCols, maxRows);

        setState(() {
          _placedRooms.add(fitted);
        });
      },
    );
  }

  // Returns a Room placed at the nearest available grid cell within bounds
  // ignoreId: an optional room id to ignore during overlap checks (useful when moving an existing room)
  Room _fitRoom(Room room, int maxCols, int maxRows, {int? ignoreId}) {
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
        if (ignoreId != null && placed.id == ignoreId) continue;
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
      final candidate = Room(
        id: room.id,
        gridX: p.x,
        gridY: p.y,
        gridW: room.gridW,
        gridH: room.gridH,
        color: room.color,
        isCircle: room.isCircle,
      );
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
    return Room(id: room.id, gridX: 0, gridY: 0, gridW: room.gridW, gridH: room.gridH, color: room.color, isCircle: room.isCircle);
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
