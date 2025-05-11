import 'models/models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';

// Local storage for ephemeral data
class LocalStorage {
  static final _secure = FlutterSecureStorage();

  // Store PIN securely
  static Future<void> savePin(String pseudonym, String pin) async {
    await _secure.write(key: 'pin_$pseudonym', value: pin);
  }

  static Future<String?> getPin(String pseudonym) async {
    return await _secure.read(key: 'pin_$pseudonym');
  }

  static Future<void> deletePin(String pseudonym) async {
    await _secure.delete(key: 'pin_$pseudonym');
  }

  // Store messages, media, and keys temporarily (deleted on session expiry)
  Future<void> saveMessage(String sessionId, Message message) async {
    final key = 'chat_$sessionId';
    final existing = await _secure.read(key: key);
    List<Map<String, dynamic>> messages = [];
    if (existing != null) {
      messages = List<Map<String, dynamic>>.from(jsonDecode(existing));
    }
    messages.add({
      'sender': message.senderPseudonym,
      'content': message.content,
      'timestamp': message.timestamp.toIso8601String(),
      'type': message.type.toString(),
    });
    await _secure.write(key: key, value: jsonEncode(messages));
  }

  Future<List<Message>> getMessages(String sessionId) async {
    final key = 'chat_$sessionId';
    final existing = await _secure.read(key: key);
    if (existing == null) return [];
    final decoded = jsonDecode(existing) as List;
    return decoded
        .map(
          (m) => Message(
            senderPseudonym: m['sender'],
            content: m['content'],
            timestamp: DateTime.parse(m['timestamp']),
            type: MessageType.values.firstWhere(
              (e) => e.toString() == m['type'],
            ),
          ),
        )
        .toList();
  }

  // Use secure storage for sensitive data
  static Future<void> storeKey(String sessionId, String keyData) async {
    await _secure.write(key: 'key_$sessionId', value: keyData);
  }

  static Future<String?> getKey(String sessionId) async {
    return await _secure.read(key: 'key_$sessionId');
  }

  // Clear all chat data on session expiry (AC-2)
  Future<void> deleteSessionData(String sessionId) async {
    final key = 'chat_$sessionId';
    await _secure.delete(key: key);
    await _secure.delete(key: 'key_$sessionId');
    // Delete media files associated with this session
    final mediaDir = Directory('/path/to/app/media/$sessionId');
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
    }
  }

  static Future<void> clearAll() async {
    await _secure.deleteAll();
  }
}
