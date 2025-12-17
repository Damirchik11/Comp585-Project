// lib/pages/home_layout_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room.dart';
import '../models/device.dart';
import '../models/placed_device.dart';
import '../widgets/grid_painter.dart';
import '../widgets/app_drawer.dart';
import 'package:smart_home_system/widgets/theme_mode_controller.dart';
import '../services/bluetooth_service.dart';
import '../services/firebase_storage_service.dart';

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
  final List<PlacedDevice> _placedDevices = [];
  final GlobalKey _canvasKey = GlobalKey(); // used to convert global->local coordinates
  final GlobalKey _deleteKey = GlobalKey(); // key for the delete area
  int _nextRoomId = 1;
  int _nextPlacedDeviceId = 1;

  // Device sources
  final BluetoothService _bluetoothService = BluetoothService();
  final FirebaseStorageService _storageService = FirebaseStorageService();

  // subscriptions
  StreamSubscription<List<SmartDevice>>? _pairedSub;
  StreamSubscription<List<SmartDevice>>? _discoveredSub;

  // combined available devices shown in toolbar
  List<SmartDevice> _availableDevices = [];

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
  void initState() {
    super.initState();

    // Listen to paired devices from Firestore (real-time)
    _pairedSub = _storageService.getPairedDevicesStream().listen((paired) {
      if (!mounted) return;
      _mergeAvailableDevices(pairedList: paired);
    }, onError: (err) {
      // If there is an auth error or Firestore error, we silently ignore and rely on BluetoothService
    });

    // Listen to discovered devices (bluetooth mock + real scan)
    _discoveredSub = _bluetoothService.devicesStream.listen((discovered) {
      if (!mounted) return;
      _mergeAvailableDevices(discoveredList: discovered);
    });
  }

  @override
  void dispose() {
    _pairedSub?.cancel();
    _discoveredSub?.cancel();
    super.dispose();
  }

  // Merges paired and discovered lists into _availableDevices (paired wins)
  void _mergeAvailableDevices({List<SmartDevice>? pairedList, List<SmartDevice>? discoveredList}) {
    final Map<String, SmartDevice> map = {for (var d in _availableDevices) d.id: d};

    if (pairedList != null) {
      for (var p in pairedList) {
        final updated = p.copyWith(isPaired: true);
        map[p.id] = updated;
      }
    }

    if (discoveredList != null) {
      for (var d in discoveredList) {
        if (map.containsKey(d.id)) {
          final existing = map[d.id]!;
          map[d.id] = existing.copyWith(rssi: d.rssi, state: d.state, isMockDevice: d.isMockDevice);
        } else {
          map[d.id] = d;
        }
      }
    }

    final combined = map.values.toList();
    combined.sort((a, b) {
      final pa = a.isPaired ? 0 : 1;
      final pb = b.isPaired ? 0 : 1;
      if (pa != pb) return pa - pb;
      return a.name.compareTo(b.name);
    });

    setState(() => _availableDevices = combined);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ThemeModeController>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Floor Plan Editor'),
        titleTextStyle: TextStyle(fontSize: controller.resolvedFontSize * 1.5),
        backgroundColor: controller.accentColor,
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
          // Top toolbox / draggable icons row + devices panel on right
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
                const Spacer(),
                _buildDevicesPanel(),
              ],
            ),
          ),

          // Canvas area (fills remaining vertical space)
          Expanded(
            child: Container(
              color: controller.backgroundColor,
              child: LayoutBuilder(builder: (context, constraints) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedRoomId = null),
                  child: SizedBox(
                    key: _canvasKey,
                    width: double.infinity,
                    height: double.infinity,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size.infinite,
                          painter: GridPainter(cellSize: cellSize),
                        ),

                        // Rooms
                        ..._placedRooms.map((r) {
                          final left = r.gridX * cellSize.toDouble();
                          final top = r.gridY * cellSize.toDouble();
                          final width = r.gridW * cellSize.toDouble();
                          final height = r.gridH * cellSize.toDouble();

                          return Positioned(
                            left: left,
                            top: top,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRoomId = r.id),
                              onDoubleTap: () async {
                                final newLabel = await _showEditLabelDialog(context, r.label);
                                if (newLabel != null) {
                                  final idx = _placedRooms.indexWhere((p) => p.id == r.id);
                                  if (idx != -1) {
                                    setState(() => _placedRooms[idx] = _placedRooms[idx].copyWith(label: newLabel));
                                  }
                                }
                              },
                              onLongPress: () async {
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
                                setState(() => _selectedRoomId = r.id);
                              },
                              onPanUpdate: (details) {
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

                                final overDelete = _isGlobalPointInDeleteArea(details.globalPosition);
                                if (overDelete != _deleteHover) setState(() => _deleteHover = overDelete);

                                setState(() {
                                  final idx = _placedRooms.indexWhere((p) => p.id == r.id);
                                  if (idx != -1) {
                                    _placedRooms[idx] = _placedRooms[idx].copyWith(gridX: gridX, gridY: gridY);
                                  }
                                });
                              },
                              onPanEnd: (details) {
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
                                  setState(() => _placedRooms[idx] = fitted);
                                }

                                _movingRoomId = null;
                                _lastPanGlobal = null;
                                if (_deleteHover) setState(() => _deleteHover = false);
                              },
                              child: Stack(
                                children: [
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

                                  if (_selectedRoomId == r.id)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Container(
                                          decoration: BoxDecoration(border: Border.all(color: Colors.black87, width: 2)),
                                        ),
                                      ),
                                    ),

                                  if (_selectedRoomId == r.id) ..._buildResizeHandles(r, width, height),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        // Placed devices (top of rooms) — FIXED overflow by removing fixed height
                        ..._placedDevices.map((pd) {
                          final left = pd.gridX * cellSize.toDouble();
                          final top = pd.gridY * cellSize.toDouble();
                          final iconSize = 26.0 * pd.iconScale;

                          return Positioned(
                            left: left,
                            top: top,
                            child: GestureDetector(
                              onTap: () => _showDeviceControls(pd),
                              onLongPress: () async {
                                final confirm = await _showConfirmDeleteDialog(context, pd.device.name);
                                if (confirm == true) {
                                  setState(() => _placedDevices.removeWhere((p) => p.id == pd.id));
                                }
                              },
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: iconSize + 18,
                                  maxWidth: 140, // prevents huge labels breaking layout
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconTheme(
                                        data: IconThemeData(size: iconSize),
                                        child: _getDeviceIcon(pd.device.type),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pd.device.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10, height: 1.1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),

                        // delete area (DragTarget)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: DragTarget<Object>(
                            key: _deleteKey,
                            onWillAccept: (data) {
                              setState(() => _deleteHover = true);
                              return true;
                            },
                            onLeave: (data) => setState(() => _deleteHover = false),
                            onAccept: (data) {
                              if (data is SmartDevice) {
                                // dragging from toolbar -> ignore
                              } else if (data is PlacedDevice) {
                                setState(() => _placedDevices.removeWhere((p) => p.id == data.id));
                              } else if (data is int) {
                                setState(() => _placedDevices.removeWhere((p) => p.id == data));
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
    return const Text(
      '',
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
        if (_isGlobalPointInDeleteArea(details.offset)) {
          setState(() => _deleteHover = false);
          return;
        }

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
        setState(() => _placedRooms.add(fitted));
      },
    );
  }

  // Devices panel
  Widget _buildDevicesPanel() {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.devices),
              const SizedBox(width: 8),
              const Text('Devices', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              PopupMenuButton<int>(
                tooltip: 'Device actions',
                itemBuilder: (ctx) => [
                  const PopupMenuItem<int>(value: 1, child: Text('Open Devices Page')),
                ],
                onSelected: (v) {
                  if (v == 1) Navigator.of(context).pushNamed('/devices');
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _availableDevices.isEmpty
                  ? const Center(child: Text('No devices available', style: TextStyle(fontSize: 12)))
                  : ListView.builder(
                      itemCount: _availableDevices.length,
                      itemBuilder: (context, index) {
                        final d = _availableDevices[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Draggable<SmartDevice>(
                            data: d,
                            feedback: Material(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blueGrey.shade700, borderRadius: BorderRadius.circular(6)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _getDeviceIcon(d.type),
                                    const SizedBox(width: 8),
                                    Text(d.name, style: const TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(opacity: 0.4, child: _deviceListTile(d)),
                            child: _deviceListTile(d),
                            onDragEnd: (details) {
                              if (_isGlobalPointInDeleteArea(details.offset)) {
                                setState(() => _deleteHover = false);
                                return;
                              }

                              final canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                              if (canvasBox == null) return;

                              final local = canvasBox.globalToLocal(details.offset);
                              final int maxCols = (canvasBox.size.width / cellSize).floor();
                              final int maxRows = (canvasBox.size.height / cellSize).floor();

                              int gridX = (local.dx / cellSize).floor();
                              int gridY = (local.dy / cellSize).floor();

                              if (gridX < 0) gridX = 0;
                              if (gridY < 0) gridY = 0;
                              if (gridX >= maxCols) gridX = maxCols - 1;
                              if (gridY >= maxRows) gridY = maxRows - 1;

                              if (_placedRooms.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Add rooms first before placing devices.')),
                                );
                                return;
                              }

                              final targetRoom = _findRoomContainingGridPoint(gridX, gridY);
                              int placeX = gridX;
                              int placeY = gridY;

                              if (targetRoom == null) {
                                final nearest = _findNearestRoomCenter(gridX, gridY);
                                if (nearest != null) {
                                  placeX = nearest.dx.toInt();
                                  placeY = nearest.dy.toInt();
                                }
                              } else {
                                placeX = gridX.clamp(targetRoom.gridX, targetRoom.gridX + targetRoom.gridW - 1);
                                placeY = gridY.clamp(targetRoom.gridY, targetRoom.gridY + targetRoom.gridH - 1);
                              }

                              final pd = PlacedDevice(
                                id: _nextPlacedDeviceId++,
                                device: d,
                                gridX: placeX,
                                gridY: placeY,
                                state: d.state,
                              );

                              setState(() => _placedDevices.add(pd));
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceListTile(SmartDevice d) {
    return Row(
      children: [
        _getDeviceIcon(d.type),
        const SizedBox(width: 8),
        Expanded(child: Text(d.name, overflow: TextOverflow.ellipsis)),
        if (d.isMockDevice)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: const Text('SIM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
          ),
        if (d.isPaired)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: const Text('PAIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
          ),
      ],
    );
  }

  Room? _findRoomContainingGridPoint(int x, int y) {
    for (final r in _placedRooms) {
      if (x >= r.gridX && x < r.gridX + r.gridW && y >= r.gridY && y < r.gridY + r.gridH) return r;
    }
    return null;
  }

  Offset? _findNearestRoomCenter(int x, int y) {
    if (_placedRooms.isEmpty) return null;
    double bestDist = double.infinity;
    Room? best;
    for (final r in _placedRooms) {
      final centerX = r.gridX + (r.gridW / 2);
      final centerY = r.gridY + (r.gridH / 2);
      final dx = centerX - x;
      final dy = centerY - y;
      final dist = dx * dx + dy * dy;
      if (dist < bestDist) {
        bestDist = dist;
        best = r;
      }
    }
    if (best == null) return null;
    final centerGridX = (best.gridX + (best.gridW / 2)).floor();
    final centerGridY = (best.gridY + (best.gridH / 2)).floor();
    return Offset(centerGridX.toDouble(), centerGridY.toDouble());
  }

  void _showDeviceControls(PlacedDevice pd) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final state = Map<String, dynamic>.from(pd.state);
        return StatefulBuilder(builder: (context, setSheetState) {
          Widget controlForState() {
            if (state.containsKey('on') && state['on'] is bool) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(pd.device.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Switch(
                    value: state['on'] as bool,
                    onChanged: (v) {
                      setSheetState(() => state['on'] = v);
                      _updatePlacedDeviceState(pd.id, state);
                    },
                  ),
                ],
              );
            }

            if (state.containsKey('brightness') && (state['brightness'] is num)) {
              double val = (state['brightness'] as num).toDouble();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pd.device.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Slider(
                    min: 0,
                    max: 100,
                    value: val,
                    onChanged: (v) {
                      setSheetState(() => state['brightness'] = v.round());
                      _updatePlacedDeviceState(pd.id, state);
                    },
                  ),
                  Text('Brightness: ${state['brightness']}')
                ],
              );
            }

            if (state.containsKey('temperature') && (state['temperature'] is num)) {
              int temp = (state['temperature'] as num).toInt();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pd.device.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setSheetState(() => state['temperature'] = temp - 1);
                          _updatePlacedDeviceState(pd.id, state);
                        },
                        child: const Text('-'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('$temp°F', style: const TextStyle(fontSize: 16)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setSheetState(() => state['temperature'] = temp + 1);
                          _updatePlacedDeviceState(pd.id, state);
                        },
                        child: const Text('+'),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pd.device.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Status: ${pd.device.status.name}'),
                const SizedBox(height: 6),
                Text('State: ${pd.state}'),
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: controlForState(),
          );
        });
      },
    );
  }

  void _updatePlacedDeviceState(int placedId, Map<String, dynamic> newState) {
    final idx = _placedDevices.indexWhere((p) => p.id == placedId);
    if (idx != -1) {
      final pd = _placedDevices[idx].copyWith(state: newState);
      setState(() => _placedDevices[idx] = pd);
      // FUTURE: call FirebaseStorageService or BluetoothService to persist/update real device
    }
  }

  Icon _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.light:
        return const Icon(Icons.lightbulb, color: Colors.amber);
      case DeviceType.thermostat:
        return const Icon(Icons.thermostat);
      case DeviceType.lock:
        return const Icon(Icons.lock);
      case DeviceType.camera:
        return const Icon(Icons.camera_alt);
      case DeviceType.sensor:
        return const Icon(Icons.sensors);
      case DeviceType.outlet:
        return const Icon(Icons.power);
      default:
        return const Icon(Icons.devices_other);
    }
  }

  // Build four corner handles
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
            _lastPanGlobal = details.globalPosition;
            final overDelete = _isGlobalPointInDeleteArea(details.globalPosition);
            if (overDelete != _deleteHover) setState(() => _deleteHover = overDelete);
          },
          onPanEnd: (details) {
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
      setState(() => _placedRooms[idx] = fitted);
    }

    _resizingRoomId = null;
    _activeResizeCorner = null;
  }

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
          title: const Text('Delete'),
          content: Text(label.isEmpty ? 'Delete this item?' : 'Delete "$label"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
          ],
        );
      },
    );
  }

  bool _isGlobalPointInDeleteArea(Offset globalPoint) {
    final deleteBox = _deleteKey.currentContext?.findRenderObject() as RenderBox?;
    if (deleteBox == null) return false;
    final topLeft = deleteBox.localToGlobal(Offset.zero);
    final rect = topLeft & deleteBox.size;
    return rect.contains(globalPoint);
  }
}
