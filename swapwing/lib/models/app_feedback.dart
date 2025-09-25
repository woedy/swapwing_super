import 'package:flutter/foundation.dart';

/// A category used to pre-fill feedback context for submissions.
class FeedbackCategory {
  final String id;
  final String title;
  final String description;
  final String placeholder;

  const FeedbackCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.placeholder,
  });

  factory FeedbackCategory.fromJson(Map<String, dynamic> json) {
    return FeedbackCategory(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      title: json['title']?.toString() ?? 'General',
      description: json['description']?.toString() ?? '',
      placeholder:
          json['placeholder']?.toString() ?? 'Share a bit more context...',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'placeholder': placeholder,
      };
}

/// Describes how satisfied a user felt at the moment of feedback.
class FeedbackSentiment {
  final int score; // 1-5 scale
  final String label;

  const FeedbackSentiment({
    required this.score,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'label': label,
      };

  factory FeedbackSentiment.fromJson(Map<String, dynamic> json) {
    final score = int.tryParse(json['score']?.toString() ?? '') ?? 3;
    return FeedbackSentiment(
      score: score.clamp(1, 5),
      label: json['label']?.toString() ?? 'Neutral',
    );
  }
}

/// Represents a submitted feedback record in-app.
class FeedbackSubmission {
  final String id;
  final String message;
  final String categoryId;
  final bool allowContact;
  final FeedbackSentiment? sentiment;
  final DateTime createdAt;
  final String? contact;

  const FeedbackSubmission({
    required this.id,
    required this.message,
    required this.categoryId,
    required this.allowContact,
    required this.createdAt,
    this.sentiment,
    this.contact,
  });

  FeedbackSubmission copyWith({
    String? id,
    String? message,
    String? categoryId,
    bool? allowContact,
    FeedbackSentiment? sentiment,
    DateTime? createdAt,
    String? contact,
  }) {
    return FeedbackSubmission(
      id: id ?? this.id,
      message: message ?? this.message,
      categoryId: categoryId ?? this.categoryId,
      allowContact: allowContact ?? this.allowContact,
      sentiment: sentiment ?? this.sentiment,
      createdAt: createdAt ?? this.createdAt,
      contact: contact ?? this.contact,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'category_id': categoryId,
        'allow_contact': allowContact,
        'sentiment': sentiment?.toJson(),
        'created_at': createdAt.toIso8601String(),
        'contact': contact,
      };

  factory FeedbackSubmission.fromJson(Map<String, dynamic> json) {
    FeedbackSentiment? sentiment;
    final sentimentJson = json['sentiment'];
    if (sentimentJson is Map<String, dynamic>) {
      sentiment = FeedbackSentiment.fromJson(sentimentJson);
    }

    return FeedbackSubmission(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      message: json['message']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? 'general',
      allowContact: json['allow_contact'] == true,
      sentiment: sentiment,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      contact: json['contact']?.toString(),
    );
  }
}
