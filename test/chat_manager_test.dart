import 'package:flutter_test/flutter_test.dart';
import 'package:ephora/chat_manager.dart';
import 'package:ephora/models/models.dart';

void main() {
  group('ChatManager', () {
    test('should start ephemeral chat', () async {
      final manager = ChatManager();
      final session = await manager.startChatSession(User(pseudonym: 'Peer'));
      expect(session.isActive, isTrue);
      expect(session.participantPseudonyms, contains('Peer'));
    });
    test('should auto-delete chat on expiry', () async {
      final manager = ChatManager();
      final session = await manager.startChatSession(User(pseudonym: 'Peer'));
      await manager.sendMessage(
        session.sessionId,
        Message(
          senderPseudonym: 'Me',
          content: 'Hello',
          timestamp: DateTime.now(),
          type: MessageType.text,
        ),
      );
      manager.expireSession(session.sessionId);
      expect(manager.getMessages(session.sessionId), isEmpty);
    });
  });
}
