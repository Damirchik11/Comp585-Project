// lib/pages/home_layout_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room.dart';
import '../widgets/grid_painter.dart';
import '../widgets/app_drawer.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';

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
  final GlobalKey _deleteKey = GlobalKey(); // key for the delete area
  int _nextRoomId = 1;

  // track moving / selected room id while the user interacts
  int? _movingRoomId;
  int? _selectedRoomId;
  int? _resizingRoomId;
  String? _activeResizeCorner; // 'tl','tr','bl','br'

  // tracking drag pointer for move-delete checks
  Offset? _lastPanGlobal;

  // whether the delete area is currently hovered (used for UI highlight)
  bool _deleteHover = false;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Floor Plan Editor'),
        titleTextStyle: TextStyle(fontSize: controller.resolvedFontSize*1.5,),
        backgroundColor: controller.accentColor,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          // Top toolbox / draggable icons row
          Container(
            height: 200,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 36),
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
              color: controller.backgroundColor,
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
                              onLongPress: () async {
                                // long-press to delete
                                final confirm = await _showConfirmDeleteDialog(context, r.label);
                                if (confirm == true) {
                                  setState(() {
                                    _placedRooms.removeWhere((p) => p.id == r.id);
                                    if (_selectedRoomId == r.id) _selectedRoomId = null;
                                  });
                                }
                              },
                              onPanStart: (details) {
                                _movingRoomId = r.id;
                                setState(() {
                                  _selectedRoomId = r.id;
                                });
                              },
                              onPanUpdate: (details) {
                                // update last global pointer for deletion checks
                                _lastPanGlobal = details.globalPosition;

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

                                // update hover state for delete area (visual feedback)
                                final overDelete = _isGlobalPointInDeleteArea(details.globalPosition);
                                if (overDelete != _deleteHover) {
                                  setState(() => _deleteHover = overDelete);
                                }

                                setState(() {
                                  final idx = _placedRooms.indexWhere((p) => p.id == r.id);
                                  if (idx != -1) {
                                    _placedRooms[idx] = _placedRooms[idx].copyWith(gridX: gridX, gridY: gridY);
                                  }
                                });
                              },
                              onPanEnd: (details) {
                                // if last pointer is in delete area -> remove
                                if (_lastPanGlobal != null && _isGlobalPointInDeleteArea(_lastPanGlobal!)) {
                                  setState(() {
                                    _placedRooms.removeWhere((p) => p.id == r.id);
                                    _deleteHover = false;
                                    if (_selectedRoomId == r.id) _selectedRoomId = null;
                                  });
                                  _movingRoomId = null;
                                  _lastPanGlobal = null;
                                  return;
                                }

                                final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                                if (canvasBox == null) {
                                  _movingRoomId = null;
                                  _lastPanGlobal = null;
                                  _deleteHover = false;
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
                                _lastPanGlobal = null;
                                if (_deleteHover) setState(() => _deleteHover = false);
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
                                  if (_selectedRoomId == r.id)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 2)),
                                        ),
                                      ),
                                    ),

                                  // resize handles (only when selected)
                                  if (_selectedRoomId == r.id) ..._buildResizeHandles(r, width, height),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        // delete area (DragTarget for toolbox drags + visual target for moves)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: DragTarget<Room>(
                            key: _deleteKey,
                            onWillAccept: (data) {
                              setState(() => _deleteHover = true);
                              return true;
                            },
                            onLeave: (data) {
                              setState(() => _deleteHover = false);
                            },
                            onAccept: (data) {
                              // If a toolbox draggable (id == -1) drops here, do nothing (we skip adding).
                              // If in future placed rooms are Draggable with data containing id, we could remove by id.
                              // To be safe, if data.id > 0, remove matching placed room.
                              if (data.id > 0) {
                                setState(() {
                                  _placedRooms.removeWhere((p) => p.id == data.id);
                                  if (_selectedRoomId == data.id) _selectedRoomId = null;
                                });
                              }
                              setState(() => _deleteHover = false);
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _deleteHover ? Colors.redAccent : Colors.red,
                                  boxShadow: [
                                    if (_deleteHover)
                                      BoxShadow(
                                        color: Colors.redAccent.withOpacity(0.4),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                  ],
                                ),
                                child: const Icon(Icons.delete, color: Colors.white, size: 28),
                              );
                            },
                          ),
                        ),
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
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        // If dropped over delete area, don't create the room
        if (_isGlobalPointInDeleteArea(details.offset)) {
          setState(() => _deleteHover = false);
          return;
        }

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
          label: '',
        );

        // find nearest available position using a grid-aware search
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
            // also update delete hover if resizing near trash
            _lastPanGlobal = details.globalPosition;
            final overDelete = _isGlobalPointInDeleteArea(details.globalPosition);
            if (overDelete != _deleteHover) setState(() => _deleteHover = overDelete);
          },
          onPanEnd: (details) {
            // if released over delete area -> delete
            if (_lastPanGlobal != null && _isGlobalPointInDeleteArea(_lastPanGlobal!)) {
              setState(() {
                _placedRooms.removeWhere((p) => p.id == r.id);
                if (_selectedRoomId == r.id) _selectedRoomId = null;
                _deleteHover = false;
              });
            } else {
              _onResizeEnd(r);
            }
            _lastPanGlobal = null;
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

  Future<bool?> _showConfirmDeleteDialog(BuildContext context, String label) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete room?'),
          content: Text(label.isEmpty ? 'Delete this room?' : 'Delete "$label"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
          ],
        );
      },
    );
  }

  // Checks whether a global coordinate (screen space) is inside the delete area widget
  bool _isGlobalPointInDeleteArea(Offset globalPoint) {
    final deleteBox = _deleteKey.currentContext?.findRenderObject() as RenderBox?;
    if (deleteBox == null) return false;
    final topLeft = deleteBox.localToGlobal(Offset.zero);
    final rect = topLeft & deleteBox.size;
    return rect.contains(globalPoint);
  }
}