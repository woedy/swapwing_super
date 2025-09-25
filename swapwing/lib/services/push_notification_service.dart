import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swapwing/config/environment.dart';
import 'package:swapwing/models/notification_preferences.dart';
import 'package:swapwing/services/analytics_service.dart';

class PushNotificationService {
  static const _preferencesKey = 'swapwing_notification_preferences';
  static const _permissionKey = 'swapwing_notification_permission';
  static const _registrationEndpoint =
      '/api/notifications/register-device/';
  static const _preferencesEndpoint =
      '/api/notifications/preferences/';

  static final ValueNotifier<NotificationPreferences> preferencesNotifier =
      ValueNotifier(NotificationPreferences.defaults());

  static final ValueNotifier<NotificationPermissionStatus>
      permissionStatusNotifier =
      ValueNotifier(NotificationPermissionStatus.unknown);

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final storedPrefs = prefs.getString(_preferencesKey);
    if (storedPrefs != null) {
      try {
        final json = jsonDecode(storedPrefs) as Map<String, dynamic>;
        preferencesNotifier.value =
            NotificationPreferences.fromJson(json);
      } catch (_) {
        preferencesNotifier.value = NotificationPreferences.defaults();
      }
    }

    final storedPermission = prefs.getString(_permissionKey);
    if (storedPermission != null) {
      final status = NotificationPermissionStatus.values.firstWhere(
        (s) => describeEnum(s) == storedPermission,
        orElse: () => NotificationPermissionStatus.unknown,
      );
      permissionStatusNotifier.value = status;
    }

    if (EnvironmentConfig.useMockData) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      final status = _mapAuthorization(settings.authorizationStatus);
      permissionStatusNotifier.value = status;
      await prefs.setString(_permissionKey, describeEnum(status));

      if (status == NotificationPermissionStatus.granted ||
          status == NotificationPermissionStatus.provisional) {
        await _registerToken(messaging);
      }
    } catch (_) {
      // If Firebase is not configured yet we silently ignore to avoid crashes.
    }

    await _syncPreferencesFromServer();
  }

  static NotificationPermissionStatus _mapAuthorization(
    AuthorizationStatus status,
  ) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return NotificationPermissionStatus.granted;
      case AuthorizationStatus.denied:
        return NotificationPermissionStatus.denied;
      case AuthorizationStatus.provisional:
        return NotificationPermissionStatus.provisional;
      case AuthorizationStatus.notDetermined:
      default:
        return NotificationPermissionStatus.unknown;
    }
  }

  static Future<NotificationPermissionStatus> requestPermission() async {
    if (EnvironmentConfig.useMockData) {
      final status = NotificationPermissionStatus.granted;
      permissionStatusNotifier.value = status;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_permissionKey, describeEnum(status));
      AnalyticsService.instance
          .logEvent('push_permission_updated', properties: {
        'status': describeEnum(status),
        'mock': true,
      });
      return status;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final status = _mapAuthorization(settings.authorizationStatus);
      permissionStatusNotifier.value = status;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_permissionKey, describeEnum(status));

      if (status == NotificationPermissionStatus.granted ||
          status == NotificationPermissionStatus.provisional) {
        await _registerToken(messaging);
      }

      AnalyticsService.instance
          .logEvent('push_permission_updated', properties: {
        'status': describeEnum(status),
        'mock': false,
      });

      return status;
    } catch (_) {
      final status = NotificationPermissionStatus.denied;
      permissionStatusNotifier.value = status;
      return status;
    }
  }

  static Future<void> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    preferencesNotifier.value = preferences;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _preferencesKey,
      jsonEncode(preferences.toJson()),
    );

    if (EnvironmentConfig.useMockData) {
      AnalyticsService.instance
          .logEvent('push_preferences_updated_mock', properties: {
        'trade': preferences.tradeActivity,
        'journey': preferences.journeyUpdates,
        'challenge': preferences.challengeHighlights,
        'community': preferences.communitySpotlights,
        'product': preferences.productAnnouncements,
      });
      return;
    }

    try {
      await http.put(
        Uri.parse('${EnvironmentConfig.apiBaseUrl}$_preferencesEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(preferences.toJson()),
      );
    } catch (_) {
      // Best-effort only. We'll retry on next open when backend is reachable.
    }
  }

  static Future<void> _registerToken(FirebaseMessaging messaging) async {
    try {
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      AnalyticsService.instance.logEvent('push_token_refreshed');

      await http.post(
        Uri.parse('${EnvironmentConfig.apiBaseUrl}$_registrationEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'platform': Platform.operatingSystem,
        }),
      );
    } catch (_) {
      // Ignore errors—registration will retry later automatically.
    }
  }

  static Future<void> _syncPreferencesFromServer() async {
    try {
      final response = await http.get(
        Uri.parse('${EnvironmentConfig.apiBaseUrl}$_preferencesEndpoint'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return;
      }

      final payload = jsonDecode(response.body);
      Map<String, dynamic>? data;
      if (payload is Map<String, dynamic>) {
        final raw = payload['data'] ?? payload['preferences'] ?? payload;
        if (raw is Map<String, dynamic>) {
          data = raw;
        }
      }

      if (data == null) {
        return;
      }

      final remote = NotificationPreferences.fromJson(data);
      preferencesNotifier.value = remote;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _preferencesKey,
        jsonEncode(remote.toJson()),
      );
    } catch (_) {
      // Ignore sync errors for now.
    }
  }
}
