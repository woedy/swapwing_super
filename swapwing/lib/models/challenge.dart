class Challenge {
  final String id;
  final String title;
  final String description;
  final String startItem;
  final String goalItem;
  final double targetValue;
  final DateTime startDate;
  final DateTime endDate;
  final String thumbnailUrl;
  final String bannerUrl;
  final List<String> rules;
  final int participantCount;
  final bool isActive;
  final bool hasJoined;
  final String prize;
  final List<ChallengeParticipant> topParticipants;
  final List<String> tags;
  final String createdBy;
  final ChallengeStatus status;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startItem,
    required this.goalItem,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
    required this.thumbnailUrl,
    required this.bannerUrl,
    required this.rules,
    required this.participantCount,
    required this.isActive,
    required this.hasJoined,
    required this.prize,
    required this.topParticipants,
    required this.tags,
    required this.createdBy,
    required this.status,
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    String? startItem,
    String? goalItem,
    double? targetValue,
    DateTime? startDate,
    DateTime? endDate,
    String? thumbnailUrl,
    String? bannerUrl,
    List<String>? rules,
    int? participantCount,
    bool? isActive,
    bool? hasJoined,
    String? prize,
    List<ChallengeParticipant>? topParticipants,
    List<String>? tags,
    String? createdBy,
    ChallengeStatus? status,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startItem: startItem ?? this.startItem,
      goalItem: goalItem ?? this.goalItem,
      targetValue: targetValue ?? this.targetValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      rules: rules ?? this.rules,
      participantCount: participantCount ?? this.participantCount,
      isActive: isActive ?? this.isActive,
      hasJoined: hasJoined ?? this.hasJoined,
      prize: prize ?? this.prize,
      topParticipants: topParticipants ?? this.topParticipants,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
    );
  }

  String get timeRemaining {
    final now = DateTime.now();
    if (status == ChallengeStatus.upcoming) {
      final difference = startDate.difference(now);
      return _formatDuration(difference, 'starts');
    } else if (status == ChallengeStatus.active) {
      final difference = endDate.difference(now);
      return _formatDuration(difference, 'ends');
    }
    return 'Ended';
  }

  String _formatDuration(Duration duration, String prefix) {
    if (duration.inDays > 0) {
      return '$prefix in ${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '$prefix in ${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '$prefix in ${duration.inMinutes}m';
    }
    return '$prefix soon';
  }
}

class ChallengeParticipant {
  final String userId;
  final String userName;
  final String avatarUrl;
  final double currentValue;
  final int rank;
  final String journeyId;
  final int tradesCompleted;
  final DateTime joinedAt;
  final DateTime lastTradeAt;

  const ChallengeParticipant({
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.currentValue,
    required this.rank,
    required this.journeyId,
    required this.tradesCompleted,
    required this.joinedAt,
    required this.lastTradeAt,
  });

  double get progressPercentage {
    // This would be calculated based on the challenge target
    return (currentValue / 1000) * 100; // Sample calculation
  }
}

enum ChallengeStatus {
  upcoming,
  active,
  ended,
}