import 'models/models.dart';
import 'dart:async';

// Chat manager for E2EE ephemeral chats
class ChatManager {
  // In-memory chat sessions and messages for demo/testing
  final Map<String, List<Message>> _sessions = {};
  final Map<String, StreamController<Message>> _messageControllers = {};
  final Map<String, StreamController<int>> _expiryControllers = {};
  final Map<String, Timer?> _expiryTimers = {};
  final Map<String, bool> _expired = {};

  // Start a new chat session
  Future<ChatSession> startChatSession(User peer) async {
    final sessionId = peer.pseudonym;
    _sessions[sessionId] = [];
    _messageControllers[sessionId] = StreamController<Message>.broadcast();
    _expiryControllers[sessionId] = StreamController<int>.broadcast();
    _expired[sessionId] = false;
    return ChatSession(
      sessionId: sessionId,
      participantPseudonyms: [peer.pseudonym],
      isActive: true,
      startedAt: DateTime.now(),
    );
  }

  // Listen for incoming messages
  Stream<Message> onMessageReceived(String sessionId) {
    return _messageControllers[sessionId]?.stream ?? const Stream.empty();
  }

  // Send a message
  Future<void> sendMessage(String sessionId, Message message) async {
    if (_expired[sessionId] == true) return;
    _sessions[sessionId]?.add(message);
    _messageControllers[sessionId]?.add(message);
  }

  // Get all messages for a session
  List<Message> getMessages(String sessionId) {
    return _sessions[sessionId] ?? [];
  }

  // Simulate BLE RSSI monitoring and expiry countdown
  void monitorProximity(String sessionId, {int rssi = -90}) {
    // If RSSI drops below -80, start 30s countdown
    if (rssi < -80 && _expiryTimers[sessionId] == null) {
      int countdown = 30;
      _expiryControllers[sessionId]?.add(countdown);
      _expiryTimers[sessionId] = Timer.periodic(Duration(seconds: 1), (timer) {
        countdown--;
        _expiryControllers[sessionId]?.add(countdown);
        if (countdown <= 0) {
          expireSession(sessionId);
          timer.cancel();
        }
      });
    } else if (rssi >= -80 && _expiryTimers[sessionId] != null) {
      // Cancel expiry if user comes back in range
      _expiryTimers[sessionId]?.cancel();
      _expiryTimers[sessionId] = null;
      _expiryControllers[sessionId]?.add(30);
    }
  }

  // Listen for expiry countdown
  Stream<int> onExpiryCountdown(String sessionId) {
    return _expiryControllers[sessionId]?.stream ?? const Stream.empty();
  }

  // Expire the session and delete all messages
  void expireSession(String sessionId) {
    _expired[sessionId] = true;
    _sessions[sessionId]?.clear();
    _messageControllers[sessionId]?.close();
    _expiryControllers[sessionId]?.close();
  }

  // Check if session is expired
  bool isExpired(String sessionId) => _expired[sessionId] == true;
}
