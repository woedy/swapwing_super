class SwapWingUser {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? bio;
  final String? location;
  final double tradeRadius;
  final List<String> preferredCategories;
  final double trustScore;
  final int totalTrades;
  final bool isVerified;
  final DateTime createdAt;

  const SwapWingUser({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.bio,
    this.location,
    this.tradeRadius = 25.0,
    this.preferredCategories = const [],
    this.trustScore = 0.0,
    this.totalTrades = 0,
    this.isVerified = false,
    required this.createdAt,
  });

  SwapWingUser copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImageUrl,
    String? bio,
    String? location,
    double? tradeRadius,
    List<String>? preferredCategories,
    double? trustScore,
    int? totalTrades,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return SwapWingUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      tradeRadius: tradeRadius ?? this.tradeRadius,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      trustScore: trustScore ?? this.trustScore,
      totalTrades: totalTrades ?? this.totalTrades,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}