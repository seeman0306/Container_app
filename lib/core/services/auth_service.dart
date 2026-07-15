import 'dart:convert';
import 'api_client.dart';
import '../utils/secure_token_storage.dart';

class AuthService {
  static Future<Map<String, String>> authHeaders() async {
    final token = await SecureTokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };
  }

  static Future<Map<String, String>> getCaptcha() async {
    final response = await ApiClient.publicGet("/api/auth/captcha");
    if (response.statusCode == 200) {
      return Map<String, String>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to get captcha");
    }
  }

  static Future<bool> sendOtp(String phoneNumber, [String? captchaId, String? captchaValue]) async {
    final Map<String, dynamic> body = {"phone": phoneNumber};
    // Captcha is optional in our new Go backend for now
    if (captchaId != null) body["captchaID"] = captchaId;
    if (captchaValue != null) body["captcha"] = captchaValue;

    try {
      final response = await ApiClient.publicPost(
        "/api/auth/send-otp",
        body,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['is_officer'] ?? false;
      } else {
        // Try to parse error as JSON, fallback to status code message
        try {
          final body = jsonDecode(response.body);
          throw Exception(body['error'] ?? "Failed to send OTP (Status: ${response.statusCode})");
        } catch (_) {
          throw Exception("Server Error: ${response.statusCode}. Please check if backend is running correctly.");
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Connection Error: $e");
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp, {String? role}) async {
    final Map<String, dynamic> body = {
      "phone": phoneNumber,
      "code": otp,
    };
    if (role != null) body["role"] = role;

    try {
      final response = await ApiClient.publicPost(
        "/api/auth/verify-otp",
        body,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        await SecureTokenStorage.saveAuthData(
          accessToken: body['token'] ?? '',
          refreshToken: body['refresh_token'] ?? '',
          role: body['role'] ?? 'CITIZEN',
        );
        if (body['user_id'] != null) {
          await SecureTokenStorage.saveUserId(body['user_id'].toString());
        }
        await SecureTokenStorage.savePhone(phoneNumber);
        return body;
      } else {
        try {
          final body = jsonDecode(response.body);
          throw Exception(body['error'] ?? "Invalid OTP");
        } catch (_) {
          throw Exception("Server Error: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception("Connection Error: $e");
    }
  }

  static Future<void> logout() async {
    await SecureTokenStorage.clear();
  }
}
