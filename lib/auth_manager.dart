import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/models.dart';

// Auth manager for signup, login, and PIN
class AuthManager {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Replace in-memory pseudonym check with backend call
  Future<bool> isPseudonymTaken(String pseudonym) async {
    final resp = await http.get(
      Uri.parse(
        'https://api.ephora.app/auth/check_pseudonym?pseudonym=$pseudonym',
      ),
    );
    if (resp.statusCode == 200) {
      return resp.body == 'true';
    }
    throw Exception('Network error');
  }

  // Replace signUp with backend call
  Future<User> signUp(String pseudonym, String password, {String? pin}) async {
    if (await isPseudonymTaken(pseudonym)) {
      throw Exception('Pseudonym is already taken');
    }
    final resp = await http.post(
      Uri.parse('https://api.ephora.app/auth/signup'),
      body: {
        'pseudonym': pseudonym,
        'password': password,
        if (pin != null) 'pin': pin,
      },
    );
    if (resp.statusCode == 201) {
      if (pin != null) await setPin(pin);
      return User(pseudonym: pseudonym, pin: pin);
    }
    throw Exception('Signup failed: ${resp.body}');
  }

  // Replace login with backend call
  Future<User> login(String pseudonym, String password, {String? pin}) async {
    final resp = await http.post(
      Uri.parse('https://api.ephora.app/auth/login'),
      body: {
        'pseudonym': pseudonym,
        'password': password,
        if (pin != null) 'pin': pin,
      },
    );
    if (resp.statusCode == 200) {
      if (pin != null) await setPin(pin);
      return User(pseudonym: pseudonym, pin: pin);
    }
    throw Exception('Login failed: ${resp.body}');
  }

  // Set a 4-digit PIN for quick unlock
  Future<void> setPin(String pin) async {
    if (pin.length == 4 && int.tryParse(pin) != null) {
      await _secureStorage.write(key: 'user_pin', value: pin);
    } else {
      throw Exception('PIN must be 4 digits');
    }
  }

  // Validate PIN
  Future<bool> validatePin(String pin) async {
    final storedPin = await _secureStorage.read(key: 'user_pin');
    return storedPin == pin;
  }

  Future<bool> get hasPin async =>
      (await _secureStorage.read(key: 'user_pin')) != null;

  Future<void> logout() async {
    // Clear session and local caches
    await _secureStorage.deleteAll();
    // TODO: Add call to LocalStorage.clear() if implemented
    await Future.delayed(Duration(milliseconds: 100));
  }

  // Anonymous signup is handled by signUp (pseudonym + password only)
  // 4-digit PIN quick unlock is handled by setPin/validatePin
  // Display warning if pseudonym is already taken is handled in signUp
}
