// lib/pages/home_layout_page.dart
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../widgets/grid_painter.dart';
import '../widgets/app_drawer.dart';

// ---- HomeLayoutPage (main editor screen) ----
class HomeLayoutPage extends StatefulWidget {
  const HomeLayoutPage({super.key});

  @override
  State<HomeLayoutPage> createState() => _HomeLayoutPageState();
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

  // track moving / selected room id while the user interacts
  int? _movingRoomId;
  int? _selectedRoomId;
  int? _resizingRoomId;
  String? _activeResizeCorner; // 'tl','tr','bl','br'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floor Plan Editor'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),
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
                Expanded(child: Container()), // pushes toolbox items to the left
              ],
            ),
          ),

          // Canvas area (fills remaining vertical space)
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: LayoutBuilder(builder: (context, constraints) {
                return GestureDetector(
                  // tap on background to deselect
                  onTap: () {
                    setState(() {
                      _selectedRoomId = null;
                    });
                  },
                  child: SizedBox(
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

                        // placed rooms (movable + resizable + labelable)
                        ..._placedRooms.map((r) {
                          final left = r.gridX * cellSize.toDouble();
                          final top = r.gridY * cellSize.toDouble();
                          final width = r.gridW * cellSize.toDouble();
                          final height = r.gridH * cellSize.toDouble();
                          final isSelected = _selectedRoomId == r.id;

                          return Positioned(
                            left: left,
                            top: top,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRoomId = r.id;
                                });
                              },
                              onDoubleTap: () async {
                                final newLabel = await _showEditLabelDialog(context, r.label);
                                if (newLabel != null) {
                                  final idx = _placedRooms.indexWhere((p) => p.id == r.id);
                                  if (idx != -1) {
                                    setState(() {
                                      _placedRooms[idx] = _placedRooms[idx].copyWith(label: newLabel);
                                    });
                                  }
                                }
                              },
                              onPanStart: (details) {
                                _movingRoomId = r.id;
                                setState(() { _selectedRoomId = r.id; });
                              },
                              onPanUpdate: (details) {
                                final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                                if (canvasBox == null) return;
                                final local = canvasBox.globalToLocal(details.globalPosition);

                                final int maxCols = (canvasBox.size.width / cellSize).floor();
                                final int maxRows = (canvasBox.size.height / cellSize).floor();

                                int gridX = (local.dx / cellSize).floor();
                                int gridY = (local.dy / cellSize).floor();

                                final int maxStartX = (maxCols - r.gridW) >= 0 ? (maxCols - r.gridW) : 0;
                                final int maxStartY = (maxRows - r.gridH) >= 0 ? (maxRows - r.gridH) : 0;
                                if (gridX < 0) gridX = 0;
                                if (gridY < 0) gridY = 0;
                                if (gridX > maxStartX) gridX = maxStartX;
                                if (gridY > maxStartY) gridY = maxStartY;

                                setState(() {
                                  final idx = _placedRooms.indexWhere((p) => p.id == r.id);
                                  if (idx != -1) {
                                    _placedRooms[idx] = _placedRooms[idx].copyWith(gridX: gridX, gridY: gridY);
                                  }
                                });
                              },
                              onPanEnd: (details) {
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
                                  final fitted = _fitRoom(current, maxCols, maxRows, ignoreId: current.id);
                                  setState(() {
                                    _placedRooms[idx] = fitted;
                                  });
                                }

                                _movingRoomId = null;
                              },
                              child: Stack(
                                children: [
                                  // room rendering
                                  r.isCircle
                                      ? Container(
                                          width: width,
                                          height: height,
                                          decoration: BoxDecoration(
                                            color: r.color,
                                            shape: BoxShape.circle,
                                            border: _movingRoomId == r.id ? Border.all(color: Colors.white, width: 3) : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: _buildLabelText(r.label),
                                        )
                                      : Container(
                                          width: width,
                                          height: height,
                                          decoration: BoxDecoration(
                                            color: r.color,
                                            border: _movingRoomId == r.id ? Border.all(color: Colors.white, width: 3) : null,
                                          ),
                                          alignment: Alignment.center,
                                          child: _buildLabelText(r.label),
                                        ),

                                  // selection outline
                                  if (isSelected)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 2)),
                                        ),
                                      ),
                                    ),

                                  // resize handles (only when selected)
                                  if (isSelected) ..._buildResizeHandles(r, width, height),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelText(String label) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  // Top toolbox draggable builder
  Widget _buildDraggableRoom(String label, Color color, int gridW, int gridH, {bool isCircle = false}) {
    final double px = gridW * cellSize.toDouble();
    final double py = gridH * cellSize.toDouble();

    return Draggable<Room>(
      data: Room(id: -1, gridX: 0, gridY: 0, gridW: gridW, gridH: gridH, color: color, isCircle: isCircle, label: ''),
      feedback: Material(
        type: MaterialType.transparency,
        child: Container(
          width: px,
          height: py,
          decoration: BoxDecoration(color: color.withOpacity(0.9), shape: isCircle ? BoxShape.circle : BoxShape.rectangle),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: Container(width: px / 2, height: py / 2, color: color)),
      child: Column(
        children: [
          Container(width: px / 2, height: py / 2, decoration: BoxDecoration(color: color, shape: isCircle ? BoxShape.circle : BoxShape.rectangle)),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
      onDragEnd: (details) {
        final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
        if (canvasBox == null) return;

        final local = canvasBox.globalToLocal(details.offset);

        final int maxCols = (canvasBox.size.width / cellSize).floor();
        final int maxRows = (canvasBox.size.height / cellSize).floor();

        int gridX = (local.dx / cellSize).floor();
        int gridY = (local.dy / cellSize).floor();

        final int maxStartX = (maxCols - gridW) >= 0 ? (maxCols - gridW) : 0;
        final int maxStartY = (maxRows - gridH) >= 0 ? (maxRows - gridH) : 0;
        if (gridX < 0) gridX = 0;
        if (gridY < 0) gridY = 0;
        if (gridX > maxStartX) gridX = maxStartX;
        if (gridY > maxStartY) gridY = maxStartY;

        final newRoom = Room(
          id: _nextRoomId++,
          gridX: gridX,
          gridY: gridY,
          gridW: gridW,
          gridH: gridH,
          color: color,
          isCircle: isCircle,
          label: '',
        );

        final fitted = _fitRoom(newRoom, maxCols, maxRows);

        setState(() {
          _placedRooms.add(fitted);
        });
      },
    );
  }

  // Build four corner handles; each returns a Positioned widget for the handle with drag handlers
  List<Widget> _buildResizeHandles(Room r, double width, double height) {
    const double handleSize = 12;
    Widget handle(String corner, double left, double top) {
      return Positioned(
        left: left,
        top: top,
        child: GestureDetector(
          onPanStart: (details) {
            _resizingRoomId = r.id;
            _activeResizeCorner = corner;
          },
          onPanUpdate: (details) {
            _onResizeDrag(r, corner, details);
          },
          onPanEnd: (details) {
            _onResizeEnd(r);
          },
          child: Container(
            width: handleSize,
            height: handleSize,
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black87)),
          ),
        ),
      );
    }

    return [
      handle('tl', -6, -6),
      handle('tr', width - 6, -6),
      handle('bl', -6, height - 6),
      handle('br', width - 6, height - 6),
    ];
  }

  void _onResizeDrag(Room r, String corner, DragUpdateDetails details) {
    final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox == null) return;

    final local = canvasBox.globalToLocal(details.globalPosition);
    final int maxCols = (canvasBox.size.width / cellSize).floor();
    final int maxRows = (canvasBox.size.height / cellSize).floor();

    final int origX = r.gridX;
    final int origY = r.gridY;
    final int origW = r.gridW;
    final int origH = r.gridH;

    int newX = origX;
    int newY = origY;
    int newW = origW;
    int newH = origH;

    if (corner == 'br') {
      int computedW = ((local.dx / cellSize).round() - origX).clamp(1, maxCols - origX);
      int computedH = ((local.dy / cellSize).round() - origY).clamp(1, maxRows - origY);
      newW = computedW;
      newH = computedH;
      if (r.isCircle) {
        final s = newW > newH ? newW : newH;
        newW = s;
        newH = s;
        if (origX + newW > maxCols) newW = maxCols - origX;
        if (origY + newH > maxRows) newH = maxRows - origY;
      }
    } else if (corner == 'bl') {
      int newGridX = (local.dx / cellSize).floor().clamp(0, origX + origW - 1);
      int computedW = (origX + origW) - newGridX;
      computedW = computedW.clamp(1, maxCols - newGridX);
      newX = newGridX;
      newW = computedW;
      int computedH = ((local.dy / cellSize).round() - origY).clamp(1, maxRows - origY);
      newH = computedH;
      if (r.isCircle) {
        final s = newW > newH ? newW : newH;
        final adjustedNewX = (origX + origW) - s;
        newX = adjustedNewX.clamp(0, maxCols - s);
        newW = s;
        newH = s;
      }
    } else if (corner == 'tr') {
      int newGridY = (local.dy / cellSize).floor().clamp(0, origY + origH - 1);
      int computedH = (origY + origH) - newGridY;
      computedH = computedH.clamp(1, maxRows - newGridY);
      newY = newGridY;
      newH = computedH;
      int computedW = ((local.dx / cellSize).round() - origX).clamp(1, maxCols - origX);
      newW = computedW;
      if (r.isCircle) {
        final s = newW > newH ? newW : newH;
        final adjustedNewY = (origY + origH) - s;
        newY = adjustedNewY.clamp(0, maxRows - s);
        newW = s;
        newH = s;
      }
    } else if (corner == 'tl') {
      int newGridX = (local.dx / cellSize).floor().clamp(0, origX + origW - 1);
      int newGridY = (local.dy / cellSize).floor().clamp(0, origY + origH - 1);
      int computedW = (origX + origW) - newGridX;
      int computedH = (origY + origH) - newGridY;
      computedW = computedW.clamp(1, maxCols - newGridX);
      computedH = computedH.clamp(1, maxRows - newGridY);
      newX = newGridX;
      newY = newGridY;
      newW = computedW;
      newH = computedH;
      if (r.isCircle) {
        final s = newW > newH ? newW : newH;
        final adjustedNewX = (origX + origW) - s;
        final adjustedNewY = (origY + origH) - s;
        newX = adjustedNewX.clamp(0, maxCols - s);
        newY = adjustedNewY.clamp(0, maxRows - s);
        newW = s;
        newH = s;
      }
    }

    setState(() {
      final idx = _placedRooms.indexWhere((p) => p.id == r.id);
      if (idx != -1) {
        _placedRooms[idx] = _placedRooms[idx].copyWith(gridX: newX, gridY: newY, gridW: newW, gridH: newH);
      }
    });
  }

  void _onResizeEnd(Room r) {
    final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox == null) {
      _resizingRoomId = null;
      _activeResizeCorner = null;
      return;
    }

    final int maxCols = (canvasBox.size.width / cellSize).floor();
    final int maxRows = (canvasBox.size.height / cellSize).floor();

    final idx = _placedRooms.indexWhere((p) => p.id == r.id);
    if (idx != -1) {
      final current = _placedRooms[idx];
      final fitted = _fitRoom(current, maxCols, maxRows, ignoreId: current.id);
      setState(() {
        _placedRooms[idx] = fitted;
      });
    }

    _resizingRoomId = null;
    _activeResizeCorner = null;
  }

  // Returns a Room placed at the nearest available grid cell within bounds
  // ignoreId: optional to ignore one room during overlap checks (useful when moving/resizing)
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

    if (fits(room)) return room;

    final startX = room.gridX.clamp(0, (maxCols - room.gridW) >= 0 ? (maxCols - room.gridW) : 0);
    final startY = room.gridY.clamp(0, (maxRows - room.gridH) >= 0 ? (maxRows - room.gridH) : 0);

    final queue = <_GridPoint>[_GridPoint(startX, startY)];
    final visited = <String>{'${startX}_$startY'};
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
        label: room.label,
      );
      if (fits(candidate)) return candidate;

      for (var d in directions) {
        final nx = p.x + d.x;
        final ny = p.y + d.y;
        if (nx < 0 || ny < 0) continue;
        if (nx + room.gridW > maxCols) continue;
        if (ny + room.gridH > maxRows) continue;
        final key = '${nx}_$ny';
        if (visited.contains(key)) continue;
        visited.add(key);
        queue.add(_GridPoint(nx, ny));
      }
    }

    return Room(id: room.id, gridX: 0, gridY: 0, gridW: room.gridW, gridH: room.gridH, color: room.color, isCircle: room.isCircle, label: room.label);
  }

  Future<String?> _showEditLabelDialog(BuildContext context, String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit label'),
          content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Room label')),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Save')),
          ],
        );
      },
    );
  }
}
