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

  factory SwapWingUser.fromJson(Map<String, dynamic> json) {
    final email = (json['email'] ?? '').toString();
    return SwapWingUser(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? email).toString(),
      email: email,
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      tradeRadius: (json['tradeRadius'] as num?)?.toDouble() ?? 25.0,
      preferredCategories: List<String>.from(
        (json['preferredCategories'] as List<dynamic>? ?? const [])
            .map((value) => value.toString()),
      ),
      trustScore: (json['trustScore'] as num?)?.toDouble() ?? 0.0,
      totalTrades: (json['totalTrades'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.now()),
    );
  }

  factory SwapWingUser.fromApi(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['user_id'] ?? '').toString();
    final email = (json['email'] ?? '').toString();
    final firstName = (json['first_name'] ?? '').toString().trim();
    final lastName = (json['last_name'] ?? '').toString().trim();
    final username = (json['username'] ?? '').toString().trim();
    final displayName = username.isNotEmpty
        ? username
        : [firstName, lastName].where((value) => value.isNotEmpty).join(' ');
    final fallbackUsername = displayName.isNotEmpty
        ? displayName
        : (email.contains('@') ? email.split('@').first : email);

    return SwapWingUser(
      id: id,
      username: fallbackUsername.isNotEmpty ? fallbackUsername : 'swapwing_user',
      email: email,
      profileImageUrl: json['profile_image_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      tradeRadius: (json['trade_radius'] as num?)?.toDouble() ?? 25.0,
      preferredCategories: List<String>.from(
        (json['preferred_categories'] as List<dynamic>? ?? const [])
            .map((value) => value.toString()),
      ),
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0.0,
      totalTrades: (json['total_trades'] as num?)?.toInt() ?? 0,
      isVerified:
          json['is_verified'] as bool? ?? json['email_verified'] as bool? ?? false,
      createdAt: DateTime.tryParse((json['created_at'] ?? json['joined_at'] ?? '')
              .toString()) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'location': location,
      'tradeRadius': tradeRadius,
      'preferredCategories': preferredCategories,
      'trustScore': trustScore,
      'totalTrades': totalTrades,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
