import 'package:flutter_test/flutter_test.dart';
import 'package:ephora/ble_manager.dart';
import 'package:ephora/models/models.dart';

void main() {
  group('BLEManager', () {
    test('should scan for devices', () async {
      final manager = BleManager();
      await manager.startScanning();
      // Simulate a scan result
      expect(manager.getNearbyUsers(), isA<Stream<List<User>>>());
    });
    test('should handle ghost mode', () async {
      final manager = BleManager();
      await manager.enableInvisibleMode();
      expect(manager.isInvisible, isTrue);
      await manager.disableInvisibleMode(User(pseudonym: 'Test'));
      expect(manager.isInvisible, isFalse);
    });
  });
}
