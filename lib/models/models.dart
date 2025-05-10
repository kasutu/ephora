// User model: pseudonym, optional avatar, bio, PIN, etc.
class User {
  final String pseudonym;
  final String? avatarUrl;
  final String? bio;
  final String? pin;
  // TODO: Add pronouns, mood badges, etc.

  User({required this.pseudonym, this.avatarUrl, this.bio, this.pin});
}

// ChatSession model: sessionId, participants, isActive, etc.
class ChatSession {
  final String sessionId;
  final List<String> participantPseudonyms;
  final bool isActive;
  final DateTime startedAt;
  // TODO: Add ephemeral key, proximity status, etc.

  ChatSession({
    required this.sessionId,
    required this.participantPseudonyms,
    required this.isActive,
    required this.startedAt,
  });
}

// Message model: sender, content, timestamp, type (text/image/emoji), etc.
class Message {
  final String senderPseudonym;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  // TODO: Add E2EE fields, media blur, etc.

  Message({
    required this.senderPseudonym,
    required this.content,
    required this.timestamp,
    required this.type,
  });
}

enum MessageType { text, image, emoji }

// AdBanner model: id, imageUrl, clickUrl, etc.
class AdBanner {
  final String id;
  final String imageUrl;
  final String clickUrl;
  // TODO: Add impression/click tracking fields.

  AdBanner({required this.id, required this.imageUrl, required this.clickUrl});
}
