enum TradeJourneyStatus { active, completed, paused }

class TradeStep {
  final String id;
  final String fromListingId;
  final String toListingId;
  final double fromValue;
  final double toValue;
  final DateTime completedAt;
  final String? notes;

  const TradeStep({
    required this.id,
    required this.fromListingId,
    required this.toListingId,
    required this.fromValue,
    required this.toValue,
    required this.completedAt,
    this.notes,
  });

  double get valueIncrease => toValue - fromValue;
  double get valueIncreasePercentage => ((toValue - fromValue) / fromValue) * 100;
}

class TradeJourney {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String title;
  final String? description;
  final String startingListingId;
  final double startingValue;
  final double targetValue;
  final List<TradeStep> tradeSteps;
  final TradeJourneyStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int likes;
  final int comments;
  final int shares;
  final bool isLikedByCurrentUser;
  final List<String> tags;

  const TradeJourney({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.title,
    this.description,
    required this.startingListingId,
    required this.startingValue,
    required this.targetValue,
    this.tradeSteps = const [],
    this.status = TradeJourneyStatus.active,
    required this.createdAt,
    this.completedAt,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLikedByCurrentUser = false,
    this.tags = const [],
  });

  double get currentValue {
    if (tradeSteps.isEmpty) return startingValue;
    return tradeSteps.last.toValue;
  }

  double get totalGain => currentValue - startingValue;
  
  double get progressPercentage {
    if (targetValue <= startingValue) return 0;
    return ((currentValue - startingValue) / (targetValue - startingValue) * 100).clamp(0, 100);
  }

  int get totalSteps => tradeSteps.length;

  TradeJourney copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? title,
    String? description,
    String? startingListingId,
    double? startingValue,
    double? targetValue,
    List<TradeStep>? tradeSteps,
    TradeJourneyStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    int? likes,
    int? comments,
    int? shares,
    bool? isLikedByCurrentUser,
    List<String>? tags,
  }) {
    return TradeJourney(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      title: title ?? this.title,
      description: description ?? this.description,
      startingListingId: startingListingId ?? this.startingListingId,
      startingValue: startingValue ?? this.startingValue,
      targetValue: targetValue ?? this.targetValue,
      tradeSteps: tradeSteps ?? this.tradeSteps,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      shares: shares ?? this.shares,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      tags: tags ?? this.tags,
    );
  }
}