import 'package:flutter_test/flutter_test.dart';
import 'package:ephora/local_storage.dart';
import 'package:ephora/models/models.dart';

void main() {
  group('LocalStorage', () {
    test('should store and delete ephemeral data', () async {
      final storage = LocalStorage();
      final sessionId = 'testsession';
      final msg = Message(
        senderPseudonym: 'Me',
        content: 'Hello',
        timestamp: DateTime.now(),
        type: MessageType.text,
      );
      await storage.saveMessage(sessionId, msg);
      final messages = await storage.getMessages(sessionId);
      expect(messages, isNotEmpty);
      await storage.deleteSessionData(sessionId);
      final afterClear = await storage.getMessages(sessionId);
      expect(afterClear, isEmpty);
    });
  });
}
