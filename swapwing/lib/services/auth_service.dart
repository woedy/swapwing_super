import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swapwing/config/environment.dart';
import 'package:swapwing/models/user.dart';
import 'package:swapwing/services/sample_data.dart';

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message';
}

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _authTokenKey = 'auth_token';
  static const String _userPayloadKey = 'user_payload';
  static const String _pendingVerificationEmailKey =
      'pending_verification_email';
  static const String _placeholderFcmToken =
      'swapwing-placeholder-device-token';

  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static SwapWingUser? _currentUser;

  static SwapWingUser? get currentUser => _currentUser;

  static Future<bool> isLoggedIn() async {
    if (EnvironmentConfig.useMockData) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    }

    final token = await _secureStorage.read(key: _authTokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  static Future<void> login(String email, String password) async {
    if (EnvironmentConfig.useMockData) {
      await _simulateNetwork();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, SampleData.currentUser.id);
      await prefs.remove(_pendingVerificationEmailKey);

      _currentUser = SampleData.currentUser;
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${EnvironmentConfig.apiBaseUrl}/api/accounts/login-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'fcm_token': _placeholderFcmToken,
        }),
      );

      if (response.statusCode != 200) {
        final error = _parseError(response.body,
            defaultMessage:
                'Unable to sign in with the provided credentials.');
        throw AuthException(error.message, code: error.code);
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (payload['data'] as Map<String, dynamic>?) ?? {};
      final token = (data['token'] ?? payload['access_token'])?.toString();

      if (token == null || token.isEmpty) {
        throw const AuthException(
          'Missing session token from server response.',
        );
      }

      final userMap = data['user'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['user'] as Map)
          : data;

      final user = SwapWingUser.fromApi(userMap);

      await _persistSession(user, token);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to connect to SwapWing right now. Please try again shortly.',
      );
    }
  }

  static Future<void> loginWithGoogle() async {
    if (EnvironmentConfig.useMockData) {
      await _simulateNetwork();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, SampleData.currentUser.id);
      await prefs.remove(_pendingVerificationEmailKey);

      _currentUser = SampleData.currentUser;
      return;
    }

    throw const AuthException('Google login is not available yet on mobile.');
  }

  static Future<String> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    final trimmedEmail = email.trim();

    if (EnvironmentConfig.useMockData) {
      await _simulateNetwork();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, SampleData.currentUser.id);
      await prefs.remove(_pendingVerificationEmailKey);

      _currentUser = SampleData.currentUser;
      return trimmedEmail;
    }

    try {
      final response = await http.post(
        Uri.parse('${EnvironmentConfig.apiBaseUrl}/api/accounts/register-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': trimmedEmail.toLowerCase(),
          'username': username.trim(),
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'password': password,
          'password2': confirmPassword,
        }),
      );

      if (response.statusCode != 201) {
        final error = _parseError(
          response.body,
          defaultMessage: 'Unable to create your account at the moment.',
        );
        throw AuthException(error.message, code: error.code);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingVerificationEmailKey, trimmedEmail);

      return trimmedEmail;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to connect to SwapWing right now. Please try again shortly.',
      );
    }
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.delete(key: _authTokenKey);
    await _secureStorage.delete(key: _userPayloadKey);
    _currentUser = null;
  }

  static Future<void> initializeUser() async {
    if (EnvironmentConfig.useMockData) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      if (userId != null) {
        _currentUser = SampleData.currentUser;
      }
      return;
    }

    final storedUser = await _secureStorage.read(key: _userPayloadKey);
    if (storedUser != null) {
      try {
        final decoded = jsonDecode(storedUser) as Map<String, dynamic>;
        _currentUser = SwapWingUser.fromJson(decoded);
      } catch (_) {
        await _secureStorage.delete(key: _userPayloadKey);
      }
    }
  }

  static Future<String?> getAuthToken() {
    return _secureStorage.read(key: _authTokenKey);
  }

  static Future<String?> getPendingVerificationEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingVerificationEmailKey);
  }

  static Future<void> clearPendingVerificationEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingVerificationEmailKey);
  }

  static Future<void> verifyEmail({
    required String email,
    String? code,
    String? token,
  }) async {
    final trimmedEmail = email.trim();

    if (EnvironmentConfig.useMockData) {
      await _simulateNetwork();
      await clearPendingVerificationEmail();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userIdKey, SampleData.currentUser.id);
      _currentUser = SampleData.currentUser;
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${EnvironmentConfig.apiBaseUrl}/api/accounts/verify-user-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': trimmedEmail.toLowerCase(),
          if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
          if (token != null && token.trim().isNotEmpty) 'token': token.trim(),
        }),
      );

      if (response.statusCode != 200) {
        final error = _parseError(
          response.body,
          defaultMessage: 'Unable to verify your email right now.',
        );
        throw AuthException(error.message, code: error.code);
      }

      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        throw const AuthException('Unexpected response from the server.');
      }

      final rawData = payload['data'];
      if (rawData is! Map<String, dynamic>) {
        throw const AuthException('Unexpected response from the server.');
      }

      final data = Map<String, dynamic>.from(rawData);
      final tokenValue = data['token']?.toString();

      if (tokenValue == null || tokenValue.isEmpty) {
        throw const AuthException(
          'Verification succeeded but no session token was returned.',
        );
      }

      final user = SwapWingUser.fromApi(data);

      await _persistSession(user, tokenValue);
      await clearPendingVerificationEmail();
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to connect to SwapWing right now. Please try again shortly.',
      );
    }
  }

  static Future<void> resendVerificationEmail(String email) async {
    final trimmedEmail = email.trim();

    if (EnvironmentConfig.useMockData) {
      await _simulateNetwork();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingVerificationEmailKey, trimmedEmail);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
            '${EnvironmentConfig.apiBaseUrl}/api/accounts/resend-email-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': trimmedEmail.toLowerCase()}),
      );

      if (response.statusCode != 200 && response.statusCode != 202) {
        final error = _parseError(
          response.body,
          defaultMessage:
              'Unable to resend the verification email right now.',
        );
        throw AuthException(error.message, code: error.code);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingVerificationEmailKey, trimmedEmail);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to connect to SwapWing right now. Please try again shortly.',
      );
    }
  }

  static Future<void> _simulateNetwork() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  static Future<void> _persistSession(
    SwapWingUser user,
    String token,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userIdKey, user.id);
    await prefs.remove(_pendingVerificationEmailKey);

    await _secureStorage.write(key: _authTokenKey, value: token);
    await _secureStorage.write(
      key: _userPayloadKey,
      value: jsonEncode(user.toJson()),
    );

    _currentUser = user;
  }

  static _AuthError _parseError(String body,
      {String defaultMessage = 'Something went wrong.'}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final errorFromErrors = _extractFirstString(decoded['errors']);
        if (errorFromErrors != null) {
          return _AuthError(errorFromErrors,
              code: _inferErrorCode(errorFromErrors));
        }

        if (decoded['detail'] != null) {
          final detail = _extractFirstString(decoded['detail']);
          if (detail != null) {
            return _AuthError(detail, code: _inferErrorCode(detail));
          }
        }

        if (decoded['message'] != null &&
            decoded['message'].toString().isNotEmpty &&
            decoded['message'].toString().toLowerCase() != 'error') {
          final message = decoded['message'].toString();
          return _AuthError(message, code: _inferErrorCode(message));
        }

        final sanitized = Map<String, dynamic>.from(decoded)
          ..remove('message')
          ..remove('detail');
        final fallback = _extractFirstString(sanitized);
        if (fallback != null) {
          return _AuthError(fallback, code: _inferErrorCode(fallback));
        }
      }
    } catch (_) {
      // ignore decoding issues
    }

    return _AuthError(defaultMessage, code: null);
  }

  static String? _extractFirstString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isNotEmpty ? trimmed : null;
    }

    if (value is Iterable) {
      for (final item in value) {
        final result = _extractFirstString(item);
        if (result != null) return result;
      }
    }

    if (value is Map) {
      for (final entry in value.entries) {
        final result = _extractFirstString(entry.value);
        if (result != null) return result;
      }
    }

    return null;
  }

  static String? _inferErrorCode(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('confirm your account') ||
        normalized.contains('resend confirmation') ||
        (normalized.contains('verify') && normalized.contains('email'))) {
      return 'email_not_verified';
    }

    if (normalized.contains('already verified')) {
      return 'email_already_verified';
    }

    if (normalized.contains('invalid') && normalized.contains('verification')) {
      return 'invalid_verification_code';
    }

    if (normalized.contains('expired') && normalized.contains('verification')) {
      return 'expired_verification_code';
    }

    return null;
  }
}

class _AuthError {
  final String message;
  final String? code;

  const _AuthError(this.message, {this.code});
}
