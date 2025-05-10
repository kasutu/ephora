import 'models/models.dart';

// Local storage for ephemeral data
class LocalStorage {
  // Ephemeral local storage for messages, media, keys
  Future<void> saveMessage(String sessionId, Message message) async {
    // TODO: Store message securely (Hive/Secure Storage)
  }

  Future<List<Message>> getMessages(String sessionId) async {
    // TODO: Retrieve messages for session
    throw UnimplementedError();
  }

  Future<void> deleteSessionData(String sessionId) async {
    // TODO: Delete all data for session
  }
}
