import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:swapwing/config/environment.dart';
import 'package:swapwing/services/auth_service.dart';

/// Represents a structured analytics event captured within the app.
class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime timestamp;
  final String? userId;

  const AnalyticsEvent({
    required this.name,
    required this.properties,
    required this.timestamp,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      if (userId != null) 'user_id': userId,
      if (properties.isNotEmpty) 'properties': properties,
    };
  }
}

/// Thin analytics client that buffers events locally while mocks are active and
/// forwards them to the backend in live mode.
class AnalyticsService {
  AnalyticsService._internal();

  static final AnalyticsService instance = AnalyticsService._internal();

  final List<AnalyticsEvent> _mockEvents = [];
  final StreamController<List<AnalyticsEvent>> _mockEventStreamController =
      StreamController<List<AnalyticsEvent>>.broadcast();

  /// Emits an immutable snapshot of tracked mock events whenever a new one is
  /// recorded. Useful for in-app debugging dashboards.
  Stream<List<AnalyticsEvent>> get mockEventsStream =>
      _mockEventStreamController.stream;

  /// Returns the currently buffered mock events. Intended for diagnostics only.
  List<AnalyticsEvent> get mockEvents => List.unmodifiable(_mockEvents);

  /// Records an analytics event with optional contextual properties.
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) async {
    final sanitized = <String, dynamic>{};
    if (properties != null) {
      for (final entry in properties.entries) {
        final value = entry.value;
        if (value == null) continue;
        sanitized[entry.key] = value;
      }
    }

    final event = AnalyticsEvent(
      name: name,
      properties: sanitized,
      timestamp: DateTime.now().toUtc(),
      userId: AuthService.currentUser?.id,
    );

    if (EnvironmentConfig.useMockData) {
      _recordMockEvent(event);
      return;
    }

    await _sendToBackend(event);
  }

  void _recordMockEvent(AnalyticsEvent event) {
    _mockEvents.add(event);
    _mockEventStreamController.add(List.unmodifiable(_mockEvents));
    developer.log(
      'Analytics event captured (mock): ${event.name}',
      name: 'AnalyticsService',
      error: event.properties.isEmpty ? null : event.properties,
    );
  }

  Future<void> _sendToBackend(AnalyticsEvent event) async {
    final baseUrl = EnvironmentConfig.apiBaseUrl;
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse('$normalizedBase/api/analytics/events/');

    try {
      final token = await AuthService.getAuthToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Token $token',
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(event.toJson()),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        developer.log(
          'Failed to deliver analytics event ${event.name}: ${response.statusCode}',
          name: 'AnalyticsService',
        );
      }
    } catch (error) {
      developer.log(
        'Error delivering analytics event ${event.name}: $error',
        name: 'AnalyticsService',
      );
    }
  }
}
