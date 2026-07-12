import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/api_constants.dart';
import '../utils/secure_token_storage.dart';

class ApiClient {
  static String get _base => ApiConstants.baseUrl;

  static Future<http.Response> get(String path) async {
    return _withRetry(() async {
      final token = await SecureTokenStorage.getAccessToken();
      return http.get(
        Uri.parse('$_base$path'),
        headers: _headers(token),
      );
    });
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    return _withRetry(() async {
      final token = await SecureTokenStorage.getAccessToken();
      return http.post(
        Uri.parse('$_base$path'),
        headers: _headers(token),
        body: jsonEncode(body),
      );
    });
  }

  static Future<http.Response> publicGet(String path) async {
    return http.get(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
    );
  }

  static Future<http.Response> publicPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    return http.post(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> _withRetry(
    Future<http.Response> Function() call,
  ) async {
    final response = await call();

    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return await call();
      } else {
        await _handleSessionExpired();
        return response;
      }
    }

    return response;
  }

  static bool _isRefreshing = false;

  static Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await SecureTokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$_base/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await SecureTokenStorage.saveAuthData(
          accessToken: data['token'],
          refreshToken: data['refresh_token'],
          role: await SecureTokenStorage.getRole() ?? '',
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  static Future<void> _handleSessionExpired() async {
    await SecureTokenStorage.clear();
    SessionEvents.notifyExpired();
  }

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
}

class SessionEvents {
  static final List<void Function()> _listeners = [];

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void notifyExpired() {
    for (final l in _listeners) {
      l();
    }
  }
}
