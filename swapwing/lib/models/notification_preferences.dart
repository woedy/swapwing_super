import 'package:flutter/foundation.dart';

class NotificationPreferences {
  final bool tradeActivity;
  final bool journeyUpdates;
  final bool challengeHighlights;
  final bool communitySpotlights;
  final bool productAnnouncements;

  const NotificationPreferences({
    required this.tradeActivity,
    required this.journeyUpdates,
    required this.challengeHighlights,
    required this.communitySpotlights,
    required this.productAnnouncements,
  });

  factory NotificationPreferences.defaults() {
    return const NotificationPreferences(
      tradeActivity: true,
      journeyUpdates: true,
      challengeHighlights: true,
      communitySpotlights: true,
      productAnnouncements: false,
    );
  }

  NotificationPreferences copyWith({
    bool? tradeActivity,
    bool? journeyUpdates,
    bool? challengeHighlights,
    bool? communitySpotlights,
    bool? productAnnouncements,
  }) {
    return NotificationPreferences(
      tradeActivity: tradeActivity ?? this.tradeActivity,
      journeyUpdates: journeyUpdates ?? this.journeyUpdates,
      challengeHighlights: challengeHighlights ?? this.challengeHighlights,
      communitySpotlights:
          communitySpotlights ?? this.communitySpotlights,
      productAnnouncements:
          productAnnouncements ?? this.productAnnouncements,
    );
  }

  Map<String, dynamic> toJson() => {
        'trade_activity': tradeActivity,
        'journey_updates': journeyUpdates,
        'challenge_highlights': challengeHighlights,
        'community_spotlights': communitySpotlights,
        'product_announcements': productAnnouncements,
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      tradeActivity: json['trade_activity'] == null
          ? NotificationPreferences.defaults().tradeActivity
          : json['trade_activity'] == true,
      journeyUpdates: json['journey_updates'] == null
          ? NotificationPreferences.defaults().journeyUpdates
          : json['journey_updates'] == true,
      challengeHighlights: json['challenge_highlights'] == null
          ? NotificationPreferences.defaults().challengeHighlights
          : json['challenge_highlights'] == true,
      communitySpotlights: json['community_spotlights'] == null
          ? NotificationPreferences.defaults().communitySpotlights
          : json['community_spotlights'] == true,
      productAnnouncements: json['product_announcements'] == null
          ? NotificationPreferences.defaults().productAnnouncements
          : json['product_announcements'] == true,
    );
  }

  @override
  String toString() =>
      'NotificationPreferences(trade=$tradeActivity, journey=$journeyUpdates, challenge=$challengeHighlights, community=$communitySpotlights, product=$productAnnouncements)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is NotificationPreferences &&
        other.tradeActivity == tradeActivity &&
        other.journeyUpdates == journeyUpdates &&
        other.challengeHighlights == challengeHighlights &&
        other.communitySpotlights == communitySpotlights &&
        other.productAnnouncements == productAnnouncements;
  }

  @override
  int get hashCode => Object.hash(
        tradeActivity,
        journeyUpdates,
        challengeHighlights,
        communitySpotlights,
        productAnnouncements,
      );
}

enum NotificationPermissionStatus {
  unknown,
  granted,
  denied,
  provisional,
}

extension NotificationPermissionStatusX on NotificationPermissionStatus {
  String get readableLabel {
    switch (this) {
      case NotificationPermissionStatus.granted:
        return 'Enabled';
      case NotificationPermissionStatus.denied:
        return 'Disabled';
      case NotificationPermissionStatus.provisional:
        return 'Limited';
      case NotificationPermissionStatus.unknown:
      default:
        return 'Pending';
    }
  }
}
