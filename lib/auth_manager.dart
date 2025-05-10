import 'models/models.dart';

// Auth manager for signup, login, and PIN
class AuthManager {
  // In-memory user store for demo/testing (replace with backend integration)
  static final Set<String> _registeredPseudonyms = {};
  static final Map<String, String> _userPasswords = {};
  static final Map<String, String?> _userPins = {};

  // Sign up, login, PIN, and session management
  Future<User> signUp(String pseudonym, String password, {String? pin}) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 300));
    if (_registeredPseudonyms.contains(pseudonym)) {
      throw Exception('Pseudonym already taken');
    }
    _registeredPseudonyms.add(pseudonym);
    _userPasswords[pseudonym] = password;
    _userPins[pseudonym] = pin;
    return User(pseudonym: pseudonym, pin: pin);
  }

  Future<User> login(String pseudonym, String password, {String? pin}) async {
    await Future.delayed(Duration(milliseconds: 200));
    if (!_registeredPseudonyms.contains(pseudonym)) {
      throw Exception('Pseudonym not found');
    }
    if (_userPasswords[pseudonym] != password) {
      throw Exception('Incorrect password');
    }
    if (_userPins[pseudonym] != null && _userPins[pseudonym] != pin) {
      throw Exception('Incorrect PIN');
    }
    return User(pseudonym: pseudonym, pin: _userPins[pseudonym]);
  }

  Future<void> setPin(String pin) async {
    // TODO: Store 4-digit PIN securely for the current user
    await Future.delayed(Duration(milliseconds: 100));
  }

  Future<void> logout() async {
    // TODO: Clear session and local caches
    await Future.delayed(Duration(milliseconds: 100));
  }
}
