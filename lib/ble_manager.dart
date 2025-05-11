import 'models/models.dart';
import 'dart:async';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// BLE manager for scanning and advertising
class BleManager {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  final StreamController<List<User>> _nearbyUsersController =
      StreamController.broadcast();
  final Map<String, User> _discoveredUsers = {};
  final Map<String, int> _rssiMap = {};

  // In-memory wave tracking for demo/testing
  final Set<String> _sentWaves = {};
  final Set<String> _receivedWaves = {};
  final StreamController<String> _mutualWaveController =
      StreamController.broadcast();
  final StreamController<String> _waveReceivedController =
      StreamController.broadcast();

  // Proximity expiry monitoring for ephemeral chat
  final Map<String, Timer?> _proximityExpiryTimers = {};
  final StreamController<String> _chatExpiredController =
      StreamController.broadcast();

  // BLE scan every 5s, handle waves
  Timer? _scanTimer;
  bool _isAdvertising = false;
  bool _isInvisible = false;
  Timer? _invisibleTimer;

  Future<void> startScanning() async {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      _discoveredUsers.clear();
      _rssiMap.clear();
      _flutterBlue.startScan(timeout: Duration(seconds: 3));
      _flutterBlue.scanResults.listen((results) {
        for (ScanResult r in results) {
          final adv = r.advertisementData;
          if (adv.localName.isNotEmpty) {
            final pseudonym = adv.localName;
            _discoveredUsers[pseudonym] = User(pseudonym: pseudonym);
            _rssiMap[pseudonym] = r.rssi;
          }
        }
        _nearbyUsersController.add(_discoveredUsers.values.toList());
      });
      _flutterBlue.stopScan();
    });
  }

  Future<void> startAdvertising(User user) async {
    // Use flutter_blue for advertising if needed
    _isAdvertising = true;
  }

  Future<void> stopAdvertising() async {
    // Use flutter_blue for stopping advertising if needed
    _isAdvertising = false;
  }

  // Enable Invisible/Ghost Mode for up to 30 min
  Future<void> enableInvisibleMode() async {
    await stopAdvertising();
    _isInvisible = true;
    _invisibleTimer?.cancel();
    _invisibleTimer = Timer(Duration(minutes: 30), () {
      _isInvisible = false;
      // Optionally, notify UI that invisible mode expired
    });
  }

  // Disable Invisible/Ghost Mode manually
  Future<void> disableInvisibleMode(User user) async {
    _invisibleTimer?.cancel();
    _isInvisible = false;
    await startAdvertising(user);
  }

  bool get isInvisible => _isInvisible;

  Stream<List<User>> getNearbyUsers() {
    if (_isInvisible) {
      return Stream.value([]);
    }
    return _nearbyUsersController.stream;
  }

  // Simulate proximity (RSSI) for each user
  double getProximity(String pseudonym) {
    return (_rssiMap[pseudonym] ?? -90).toDouble();
  }

  Future<void> sendWave(String peerPseudonym) async {
    _sentWaves.add(peerPseudonym);
    // Simulate peer waving back after a short delay for demo
    await Future.delayed(Duration(milliseconds: 800));
    _receivedWaves.add(peerPseudonym);
    // Simulate receiving a wave from peer (for demo/testing)
    _waveReceivedController.add(peerPseudonym);
    if (_sentWaves.contains(peerPseudonym) &&
        _receivedWaves.contains(peerPseudonym)) {
      _mutualWaveController.add(peerPseudonym);
    }
  }

  Stream<String> onMutualWave() => _mutualWaveController.stream;

  Stream<String> onWaveReceived() {
    // Listen for incoming waves (simulated)
    return _waveReceivedController.stream;
  }

  // Stream to simulate proximity changes for a peer
  Stream<double> onProximityChanged(String peerPseudonym) {
    // Simulate RSSI changes every 5s for the given peer
    return Stream.periodic(
      Duration(seconds: 5),
      (_) => getProximity(peerPseudonym),
    );
  }

  // Call this to monitor proximity for a chat peer
  void monitorProximityForChat(String peerPseudonym) {
    onProximityChanged(peerPseudonym).listen((rssi) {
      if (rssi < -80) {
        // RSSI threshold for ~10m
        // Start expiry timer if not already running
        if (_proximityExpiryTimers[peerPseudonym] == null) {
          _proximityExpiryTimers[peerPseudonym] = Timer(
            Duration(seconds: 30),
            () {
              _chatExpiredController.add(peerPseudonym);
              // Clean up timer
              _proximityExpiryTimers[peerPseudonym]?.cancel();
              _proximityExpiryTimers.remove(peerPseudonym);
            },
          );
        }
      } else {
        // Cancel expiry timer if peer is back in range
        _proximityExpiryTimers[peerPseudonym]?.cancel();
        _proximityExpiryTimers.remove(peerPseudonym);
      }
    });
  }

  Stream<String> onChatExpired() => _chatExpiredController.stream;

  // Real BLE matchmaking: fetch peer list from backend
  Future<void> fetchPeersFromBackend() async {
    final resp = await http.get(
      Uri.parse('https://api.ephora.app/ble/peers?myPseudonym=ME'),
    );
    if (resp.statusCode == 200) {
      final peers = jsonDecode(resp.body) as List;
      _discoveredUsers.clear();
      for (final peer in peers) {
        _discoveredUsers[peer['pseudonym']] = User(
          pseudonym: peer['pseudonym'],
        );
        _rssiMap[peer['pseudonym']] = peer['rssi'];
      }
      _nearbyUsersController.add(_discoveredUsers.values.toList());
    }
  }
}
