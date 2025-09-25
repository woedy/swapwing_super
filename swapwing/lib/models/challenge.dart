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
  final ChallengeParticipant? currentUserProgress;

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
    this.currentUserProgress,
  });

  factory Challenge.fromApi(Map<String, dynamic> json) {
    final startDate = _parseDate(json['start_date'] ?? json['start_at']);
    final endDate = _parseDate(json['end_date'] ?? json['end_at']);
    final rules = _parseStringList(json['rules']);
    final tags = _parseStringList(json['tags']);
    final participantsRaw = json['top_participants'] is List
        ? List<Map<String, dynamic>>.from(
            (json['top_participants'] as List)
                .whereType<Map<String, dynamic>>(),
          )
        : const <Map<String, dynamic>>[];
    final topParticipants = participantsRaw
        .map(ChallengeParticipant.fromApi)
        .toList(growable: false);
    final progressRaw = json['current_user_progress'];
    final currentUserProgress = progressRaw is Map<String, dynamic>
        ? ChallengeParticipant.fromApi(progressRaw)
        : null;

    final targetValue = (json['target_value'] as num?)?.toDouble() ??
        (json['goal_value'] as num?)?.toDouble() ??
        0.0;
    final participantCount = (json['participant_count'] as num?)?.toInt() ??
        (json['participants'] as num?)?.toInt() ??
        topParticipants.length;
    final statusString = json['status']?.toString();
    final isActiveFlag = json['is_active'] as bool? ??
        json['active'] as bool? ??
        statusString?.toLowerCase() == 'active';
    final status = _parseStatus(
      statusString,
      isActiveFlag,
      startDate,
      endDate,
    );

    return Challenge(
      id: (json['id'] ?? json['challenge_id'] ?? '').toString(),
      title: (json['title'] ?? 'Challenge').toString(),
      description: (json['description'] ?? '').toString(),
      startItem: (json['start_item'] ?? json['starting_item'] ?? '').toString(),
      goalItem: (json['goal_item'] ?? json['ending_item'] ?? '').toString(),
      targetValue: targetValue,
      startDate: startDate,
      endDate: endDate,
      thumbnailUrl: (json['thumbnail_url'] ?? json['thumbnail'] ?? '').toString(),
      bannerUrl: (json['banner_url'] ?? json['banner_image'] ?? '').toString(),
      rules: rules,
      participantCount: participantCount,
      isActive: status == ChallengeStatus.active,
      hasJoined: json['has_joined'] as bool? ??
          json['joined'] as bool? ??
          currentUserProgress != null,
      prize: (json['prize'] ?? '').toString(),
      topParticipants: topParticipants,
      tags: tags,
      createdBy: (json['created_by'] ?? json['host'] ?? 'SwapWing').toString(),
      status: status,
      currentUserProgress: currentUserProgress,
    );
  }

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
    ChallengeParticipant? currentUserProgress,
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
      currentUserProgress: currentUserProgress ?? this.currentUserProgress,
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

  factory ChallengeParticipant.fromApi(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;
    final avatar = (json['avatar_url'] ??
            json['profile_image'] ??
            user?['avatar_url'] ??
            user?['profile_image_url'])
        ?.toString();

    return ChallengeParticipant(
      userId: (json['user_id'] ?? user?['id'] ?? '').toString(),
      userName: (json['user_name'] ??
              json['username'] ??
              user?['username'] ??
              user?['display_name'] ??
              'Participant')
          .toString(),
      avatarUrl: avatar ?? '',
      currentValue: (json['current_value'] as num?)?.toDouble() ??
          (json['value'] as num?)?.toDouble() ??
          (json['total_value'] as num?)?.toDouble() ??
          0.0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      journeyId: (json['journey_id'] ?? json['journey'] ?? '').toString(),
      tradesCompleted: (json['trades_completed'] as num?)?.toInt() ??
          (json['trade_count'] as num?)?.toInt() ??
          0,
      joinedAt: _parseDate(json['joined_at'] ?? json['joined']),
      lastTradeAt: _parseDate(json['last_trade_at'] ?? json['updated_at']),
    );
  }

  ChallengeParticipant copyWith({
    String? userId,
    String? userName,
    String? avatarUrl,
    double? currentValue,
    int? rank,
    String? journeyId,
    int? tradesCompleted,
    DateTime? joinedAt,
    DateTime? lastTradeAt,
  }) {
    return ChallengeParticipant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentValue: currentValue ?? this.currentValue,
      rank: rank ?? this.rank,
      journeyId: journeyId ?? this.journeyId,
      tradesCompleted: tradesCompleted ?? this.tradesCompleted,
      joinedAt: joinedAt ?? this.joinedAt,
      lastTradeAt: lastTradeAt ?? this.lastTradeAt,
    );
  }

  double get progressPercentage {
    // This would be calculated based on the challenge target
    return (currentValue / 1000) * 100; // Sample calculation
  }
}

class ChallengeProgressUpdate {
  final String id;
  final String challengeId;
  final String userId;
  final String userName;
  final String avatarUrl;
  final double previousValue;
  final double newValue;
  final int tradesCompleted;
  final String message;
  final DateTime timestamp;

  const ChallengeProgressUpdate({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.avatarUrl,
    required this.previousValue,
    required this.newValue,
    required this.tradesCompleted,
    required this.message,
    required this.timestamp,
  });

  factory ChallengeProgressUpdate.fromApi(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;
    final newValue = (json['new_value'] as num?)?.toDouble() ??
        (json['current_value'] as num?)?.toDouble() ??
        (json['value'] as num?)?.toDouble() ??
        0.0;
    final previousValue = (json['previous_value'] as num?)?.toDouble() ??
        (json['old_value'] as num?)?.toDouble() ??
        newValue;

    return ChallengeProgressUpdate(
      id: (json['id'] ?? json['event_id'] ?? '').toString(),
      challengeId:
          (json['challenge_id'] ?? json['challenge'] ?? '').toString(),
      userId: (json['user_id'] ?? user?['id'] ?? '').toString(),
      userName: (json['user_name'] ??
              user?['username'] ??
              user?['display_name'] ??
              'Participant')
          .toString(),
      avatarUrl: (json['avatar_url'] ??
              user?['avatar_url'] ??
              user?['profile_image_url'] ??
              '')
          .toString(),
      previousValue: previousValue,
      newValue: newValue,
      tradesCompleted: (json['trades_completed'] as num?)?.toInt() ??
          (json['trade_count'] as num?)?.toInt() ??
          0,
      message: (json['message'] ?? json['note'] ?? '').toString(),
      timestamp:
          _parseDate(json['timestamp'] ?? json['created_at'] ?? json['logged_at']),
    );
  }

  bool get isGain => newValue >= previousValue;

  double get valueDelta => newValue - previousValue;

  ChallengeProgressUpdate copyWith({
    String? id,
    String? challengeId,
    String? userId,
    String? userName,
    String? avatarUrl,
    double? previousValue,
    double? newValue,
    int? tradesCompleted,
    String? message,
    DateTime? timestamp,
  }) {
    return ChallengeProgressUpdate(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      previousValue: previousValue ?? this.previousValue,
      newValue: newValue ?? this.newValue,
      tradesCompleted: tradesCompleted ?? this.tradesCompleted,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

ChallengeStatus _parseStatus(
  String? rawStatus,
  bool isActive,
  DateTime startDate,
  DateTime endDate,
) {
  if (rawStatus != null && rawStatus.isNotEmpty) {
    switch (rawStatus.toLowerCase()) {
      case 'active':
      case 'live':
        return ChallengeStatus.active;
      case 'upcoming':
      case 'pending':
        return ChallengeStatus.upcoming;
      case 'ended':
      case 'complete':
      case 'completed':
        return ChallengeStatus.ended;
    }
  }

  if (isActive) {
    return ChallengeStatus.active;
  }

  final now = DateTime.now();
  if (now.isBefore(startDate)) {
    return ChallengeStatus.upcoming;
  }
  if (now.isAfter(endDate)) {
    return ChallengeStatus.ended;
  }
  return ChallengeStatus.active;
}

enum ChallengeStatus {
  upcoming,
  active,
  ended,
}