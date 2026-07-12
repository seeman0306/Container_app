import 'secure_token_storage.dart';

class TokenStorage {
  static Future<String?> getToken() => SecureTokenStorage.getAccessToken();
  static Future<void> saveToken(String token) => SecureTokenStorage.saveAccessToken(token);
  static Future<void> saveRole(String role) => SecureTokenStorage.saveRole(role);
  static Future<String?> getRole() => SecureTokenStorage.getRole();
  static Future<void> clear() => SecureTokenStorage.clear();
}
