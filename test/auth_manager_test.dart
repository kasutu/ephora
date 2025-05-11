import 'package:flutter_test/flutter_test.dart';
import 'package:ephora/auth_manager.dart';

void main() {
  group('AuthManager', () {
    test('should set and validate PIN', () async {
      final manager = AuthManager();
      await manager.setPin('1234');
      expect(await manager.validatePin('1234'), isTrue);
      expect(await manager.validatePin('0000'), isFalse);
    });
    test('should throw on invalid PIN', () async {
      final manager = AuthManager();
      expect(() => manager.setPin('12'), throwsException);
      expect(() => manager.setPin('abcd'), throwsException);
    });
  });
}
