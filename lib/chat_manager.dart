import 'models/models.dart';
import 'dart:async';
import 'ble_manager.dart';
import 'dart:typed_data';
import 'dart:convert';

// Chat manager for E2EE ephemeral chats
class ChatManager {
  // In-memory chat sessions and messages for demo/testing
  final Map<String, List<Message>> _sessions = {};
  final Map<String, StreamController<Message>> _messageControllers = {};
  final Map<String, StreamController<int>> _expiryControllers = {};
  final Map<String, Timer?> _expiryTimers = {};
  final Map<String, bool> _expired = {};
  final Map<String, StreamSubscription<double>?> _proximitySubs = {};
  final BleManager _bleManager = BleManager();

  // TODO: Encrypt/decrypt messages with ephemeral session keys (E2EE)
  // TODO: Trigger auto-deletion when BLE proximity lost for 30s (AC-2)
  // TODO: Show 'Chat expired' banner before closing session
  // TODO: Support text, emoji, image sharing (AC-2, AC-5.1)
  // TODO: Inject banner ad every 5 messages (AC-4)
  // Acceptance Criteria AC-2, AC-4, AC-5.1: Ephemeral chat, auto-delete, ad injection

  Future<void> setupE2EESession(String myId, String peerId) async {
    // Stub for E2EE setup, to be implemented later
  }

  Future<String> encryptMessage(String message) async {
    // Stub for encryption, to be implemented later
    return message;
  }

  Future<String> decryptMessage(String encrypted) async {
    // Stub for decryption, to be implemented later
    return encrypted;
  }

  // Securely delete all chat messages and media for a session
  Future<void> deleteChatSession(String sessionId) async {
    // TODO: Delete from secure local storage
    _sessions.remove(sessionId);
    // TODO: Delete any media files associated with this session
    // Optionally notify UI
  }

  // Listen for BLE chat expiry and auto-delete chat
  void listenForChatExpiry(Stream<String> chatExpiredStream) {
    chatExpiredStream.listen((peerPseudonym) {
      final sessionId = _findSessionIdByPeer(peerPseudonym);
      if (sessionId != null) {
        deleteChatSession(sessionId);
        // TODO: Show "Chat expired" banner in UI
      }
    });
  }

  String? _findSessionIdByPeer(String peerPseudonym) {
    // TODO: Map peer pseudonym to sessionId
    return _sessions.keys.firstWhere(
      (id) => id.contains(peerPseudonym),
      orElse: () => '',
    );
  }

  // Start a new chat session
  Future<ChatSession> startChatSession(User peer) async {
    final sessionId = peer.pseudonym;
    _sessions[sessionId] = [];
    _messageControllers[sessionId] = StreamController<Message>.broadcast();
    _expiryControllers[sessionId] = StreamController<int>.broadcast();
    _expired[sessionId] = false;
    _proximitySubs[sessionId]?.cancel();
    int outOfRangeSeconds = 0;
    _proximitySubs[sessionId] = _bleManager
        .onProximityChanged(peer.pseudonym)
        .listen((rssi) {
          if (_expired[sessionId] == true) return;
          if (rssi < -80) {
            outOfRangeSeconds += 5;
            int countdown = 30 - outOfRangeSeconds;
            if (countdown <= 0) {
              expireSession(sessionId);
            } else {
              _expiryControllers[sessionId]?.add(countdown);
            }
          } else {
            outOfRangeSeconds = 0;
            _expiryControllers[sessionId]?.add(30);
          }
        });
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
    _expiryTimers[sessionId]?.cancel();
    _proximitySubs[sessionId]?.cancel();
    // TODO: Also delete any media from local storage if implemented
  }

  // Check if session is expired
  bool isExpired(String sessionId) => _expired[sessionId] == true;
}
