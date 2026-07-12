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
    final response = await ApiClient.publicGet("/api/auth/citizen/captcha");
    if (response.statusCode == 200) {
      return Map<String, String>.from(jsonDecode(response.body));
    } else {
      throw Exception("Failed to get captcha");
    }
  }

  static Future<bool> sendOtp(String phoneNumber, [String? captchaId, String? captchaValue]) async {
    final Map<String, dynamic> body = {"phone": phoneNumber};
    if (captchaId != null) body["captchaID"] = captchaId;
    if (captchaValue != null) body["captcha"] = captchaValue;

    final response = await ApiClient.publicPost(
      "/api/auth/citizen/send-otp",
      body,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['is_officer'] ?? false;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? "Failed to send OTP");
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp, {String? role}) async {
    final Map<String, dynamic> body = {
      "phone": phoneNumber,
      "code": otp,
    };
    if (role != null) body["role"] = role;

    final response = await ApiClient.publicPost(
      "/api/auth/citizen/verify-otp",
      body,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      await SecureTokenStorage.saveAuthData(
        accessToken: body['token'],
        refreshToken: body['refresh_token'],
        role: body['role'] ?? 'CITIZEN',
      );
      if (body['user_id'] != null) {
        await SecureTokenStorage.saveUserId(body['user_id'].toString());
      }
      return body;
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? "Invalid OTP");
    }
  }

  static Future<void> logout() async {
    await SecureTokenStorage.clear();
  }
}
