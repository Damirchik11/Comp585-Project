import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/room.dart';

/// Cloud Firestore storage service for user data
/// Replaces local SharedPreferences with cloud-based storage
class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Reference to user's document
  DocumentReference? get _userDoc {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId);
  }

  // ==================== PAIRED DEVICES ====================

  /// Save a paired device to Firestore
  Future<void> savePairedDevice(SmartDevice device) async {
    if (_userDoc == null) throw 'User not authenticated';

    await _userDoc!
        .collection('pairedDevices')
        .doc(device.id)
        .set({
      'id': device.id,
      'name': device.name,
      'type': device.type.toString().split('.').last,
      'status': device.status.toString().split('.').last,
      'isMockDevice': device.isMockDevice,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get stream of paired devices (real-time updates)
  Stream<List<SmartDevice>> getPairedDevicesStream() {
    if (_userDoc == null) return Stream.value([]);

    return _userDoc!
        .collection('pairedDevices')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SmartDevice(
          id: data['id'] as String,
          name: data['name'] as String,
          type: _parseDeviceType(data['type'] as String),
          status: _parseDeviceStatus(data['status'] as String),
          isMockDevice: data['isMockDevice'] as bool? ?? false,
        );
      }).toList();
    });
  }


  /// Remove a paired device from Firestore
  Future<void> removePairedDevice(String deviceId) async {
    if (_userDoc == null) throw 'User not authenticated';

    await _userDoc!.collection('pairedDevices').doc(deviceId).delete();
  }

  // ==================== ROOM LAYOUTS ====================

  /// Save room layout to Firestore
  Future<void> saveRoomLayout(List<Room> rooms) async {
    if (_userDoc == null) throw 'User not authenticated';

    final roomsData = rooms.map((room) => {
      'name': room.name,
      'x': room.position.dx,
      'y': room.position.dy,
      'width': room.size.width,
      'height': room.size.height,
    }).toList();

    await _userDoc!.set({
      'roomLayout': roomsData,
      'layoutUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get stream of room layouts (real-time updates)
  Stream<List<Room>> getRoomLayoutStream() {
    if (_userDoc == null) return Stream.value([]);

    return _userDoc!.snapshots().map((doc) {
      if (!doc.exists) return <Room>[];
      
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('roomLayout')) return <Room>[];

      final roomsData = data['roomLayout'] as List<dynamic>;
      return roomsData.map((roomData) {
        return Room(
          name: roomData['name'] as String,
          position: Offset(
            (roomData['x'] as num).toDouble(),
            (roomData['y'] as num).toDouble(),
          ),
          size: Size(
            (roomData['width'] as num).toDouble(),
            (roomData['height'] as num).toDouble(),
          ),
        );
      }).toList();
    });
  }

  /// Get room layout once (no real-time updates)
  Future<List<Room>> getRoomLayout() async {
    if (_userDoc == null) return [];

    final doc = await _userDoc!.get();
    if (!doc.exists) return [];

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey('roomLayout')) return [];

    final roomsData = data['roomLayout'] as List<dynamic>;
    return roomsData.map((roomData) {
      return Room(
        name: roomData['name'] as String,
        position: Offset(
          (roomData['x'] as num).toDouble(),
          (roomData['y'] as num).toDouble(),
        ),
        size: Size(
          (roomData['width'] as num).toDouble(),
          (roomData['height'] as num).toDouble(),
        ),
      );
    }).toList();
  }

  // ==================== USER SETTINGS ====================

  /// Save user settings to Firestore
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    if (_userDoc == null) throw 'User not authenticated';

    await _userDoc!.set({
      'settings': settings,
      'settingsUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get stream of user settings (real-time updates)
  Stream<Map<String, dynamic>> getUserSettingsStream() {
    if (_userDoc == null) return Stream.value({});

    return _userDoc!.snapshots().map((doc) {
      if (!doc.exists) return <String, dynamic>{};
      
      final data = doc.data() as Map<String, dynamic>?;
      return data?['settings'] as Map<String, dynamic>? ?? {};
    });
  }

  /// Get user settings once (no real-time updates)
  Future<Map<String, dynamic>> getUserSettings() async {
    if (_userDoc == null) return {};

    final doc = await _userDoc!.get();
    if (!doc.exists) return {};

    final data = doc.data() as Map<String, dynamic>?;
    return data?['settings'] as Map<String, dynamic>? ?? {};
  }

  // ==================== HELPERS ====================

  DeviceType _parseDeviceType(String typeString) {
    switch (typeString) {
      case 'light':
        return DeviceType.light;
      case 'thermostat':
        return DeviceType.thermostat;
      case 'lock':
        return DeviceType.lock;
      case 'camera':
        return DeviceType.camera;
      case 'speaker':
        return DeviceType.speaker;
      default:
        return DeviceType.light;
    }
  }

  DeviceStatus _parseDeviceStatus(String statusString) {
    switch (statusString) {
      case 'on':
        return DeviceStatus.on;
      case 'off':
        return DeviceStatus.off;
      case 'offline':
        return DeviceStatus.offline;
      default:
        return DeviceStatus.offline;
    }
  }

  /// Enable offline persistence (called once at app startup)
  static Future<void> enableOfflinePersistence() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      // Offline persistence already enabled or not supported
    }
  }
}
