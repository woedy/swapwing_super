import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swapwing/config/environment.dart';
import 'package:swapwing/models/app_feedback.dart';
import 'package:swapwing/services/analytics_service.dart';

class FeedbackServiceException implements Exception {
  final String message;

  const FeedbackServiceException(this.message);

  @override
  String toString() => 'FeedbackServiceException: $message';
}

class FeedbackService {
  static const _feedbackStorageKey = 'swapwing_feedback_history';
  static const _fallbackEndpoint = '/api/support/feedback/';

  static final List<FeedbackCategory> _mockCategories = [
    FeedbackCategory(
      id: 'bug',
      title: 'Report a bug',
      description: 'Something not working as expected? Let us know so we can fix it quickly.',
      placeholder: 'Describe what happened and any steps to reproduce the bug.',
    ),
    FeedbackCategory(
      id: 'idea',
      title: 'Suggest an idea',
      description: 'Share features or improvements that would make SwapWing better for you.',
      placeholder: 'Tell us about your idea and why it would help the community.',
    ),
    FeedbackCategory(
      id: 'praise',
      title: 'Share praise',
      description: 'Love something about SwapWing? We would love to hear about it!',
      placeholder: 'What made your experience great?',
    ),
    FeedbackCategory(
      id: 'support',
      title: 'Get support',
      description: 'Need help with your account or a trade? Our team is ready to assist.',
      placeholder: 'Include any details our support team should know.',
    ),
  ];

  const FeedbackService();

  static Future<List<FeedbackCategory>> fetchCategories() async {
    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 250));
      return _mockCategories;
    }

    try {
      final response = await http.get(
        Uri.parse('${EnvironmentConfig.apiBaseUrl}$_fallbackEndpoint'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return _mockCategories;
      }

      final payload = jsonDecode(response.body);
      final data = payload is Map<String, dynamic>
          ? payload['results'] ?? payload['data'] ?? payload['categories']
          : payload;

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(FeedbackCategory.fromJson)
            .toList();
      }

      return _mockCategories;
    } catch (_) {
      return _mockCategories;
    }
  }

  static Future<List<FeedbackSubmission>> fetchRecentSubmissions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_feedbackStorageKey) ?? <String>[];
    return raw
        .map((entry) {
          try {
            return jsonDecode(entry) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .map(FeedbackSubmission.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<FeedbackSubmission> submitFeedback({
    required FeedbackCategory category,
    required String message,
    FeedbackSentiment? sentiment,
    bool allowContact = false,
    String? contact,
  }) async {
    if (message.trim().isEmpty) {
      throw const FeedbackServiceException(
        'Please share a short description so our team can follow up.',
      );
    }

    final trimmedMessage = message.trim();
    FeedbackSubmission submission = FeedbackSubmission(
      id: UniqueKey().toString(),
      message: trimmedMessage,
      categoryId: category.id,
      allowContact: allowContact,
      sentiment: sentiment,
      createdAt: DateTime.now(),
      contact: contact?.trim().isEmpty ?? true ? null : contact!.trim(),
    );

    if (EnvironmentConfig.useMockData) {
      await Future.delayed(const Duration(milliseconds: 450));
      await _cacheSubmission(submission);
      AnalyticsService.instance.logEvent('feedback_submitted_mock', properties: {
        'category': category.id,
        'sentiment': sentiment?.score,
      });
      return submission;
    }

    try {
      final response = await http.post(
        Uri.parse('${EnvironmentConfig.apiBaseUrl}$_fallbackEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category': category.id,
          'message': trimmedMessage,
          'allow_contact': allowContact,
          'sentiment_score': sentiment?.score,
          'sentiment_label': sentiment?.label,
          if (submission.contact != null) 'contact': submission.contact,
        }),
      );

      if (response.statusCode >= 400) {
        throw const FeedbackServiceException(
          'We could not send your feedback right now. Please try again shortly.',
        );
      }

      final payload = jsonDecode(response.body);
      final data = payload is Map<String, dynamic>
          ? payload['data'] ?? payload['feedback'] ?? payload
          : payload;

      if (data is Map<String, dynamic>) {
        submission = submission.copyWith(
          id: data['id']?.toString(),
          createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ??
              submission.createdAt,
        );
      }

      AnalyticsService.instance.logEvent('feedback_submitted', properties: {
        'category': category.id,
        'sentiment': sentiment?.score,
      });

      await _cacheSubmission(submission);
      return submission;
    } on FeedbackServiceException {
      rethrow;
    } catch (_) {
      throw const FeedbackServiceException(
        'Unable to connect to SwapWing right now. Please try again later.',
      );
    }
  }

  static Future<void> _cacheSubmission(FeedbackSubmission submission) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_feedbackStorageKey) ?? <String>[];
    final updated = [submission.toJson()].map(jsonEncode).toList();
    updated.addAll(existing.take(9));
    await prefs.setStringList(_feedbackStorageKey, updated);
  }
}
