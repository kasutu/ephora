import 'models/models.dart';
import 'dart:async';

// BLE manager for scanning and advertising
class BleManager {
  // Simulated BLE scan: emits a list of mock users every 5 seconds
  final Stream<List<User>> _mockNearbyUsersStream = Stream.periodic(
    Duration(seconds: 5),
    (count) {
      // Simulate 3 users with varying proximity (RSSI)
      return [
        User(pseudonym: 'CosmicTaco92'),
        User(pseudonym: 'GhostedU'),
        User(pseudonym: 'VibingStar', bio: '✨Vibing✨'),
      ];
    },
  );

  // In-memory wave tracking for demo/testing
  final Set<String> _sentWaves = {};
  final Set<String> _receivedWaves = {};
  final StreamController<String> _mutualWaveController =
      StreamController.broadcast();
  final StreamController<String> _waveReceivedController =
      StreamController.broadcast();

  // BLE scan every 5s, advertise pseudonym, handle waves
  Future<void> startScanning() async {
    // TODO: Implement BLE scan logic (every 5s)
  }

  Future<void> startAdvertising(User user) async {
    // TODO: Start BLE advertising with pseudonym
  }

  Future<void> stopAdvertising() async {
    // TODO: Stop BLE advertising (Invisible/Ghost mode)
  }

  Stream<List<User>> getNearbyUsers() {
    // TODO: Replace with real BLE scan results
    return _mockNearbyUsersStream;
  }

  // Simulate proximity (RSSI) for each user
  double getProximity(String pseudonym) {
    // Return a mock RSSI value based on pseudonym
    switch (pseudonym) {
      case 'CosmicTaco92':
        return -50; // green (close)
      case 'GhostedU':
        return -70; // yellow (medium)
      case 'VibingStar':
        return -85; // red (far)
      default:
        return -90;
    }
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

  Stream<double> onProximityChanged(String peerPseudonym) {
    // TODO: Monitor RSSI for proximity
    throw UnimplementedError();
  }
}
