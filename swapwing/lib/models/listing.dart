import 'package:swapwing/models/user.dart';

/// Categories supported by the marketplace listing API.
enum ListingCategory {
  goods,
  services,
  digital,
  automotive,
  electronics,
  fashion,
  home,
  sports,
}

extension ListingCategoryX on ListingCategory {
  /// Convert a backend string into a [ListingCategory].
  static ListingCategory fromName(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return ListingCategory.values.firstWhere(
      (category) => category.name == normalized,
      orElse: () => ListingCategory.goods,
    );
  }

  /// User-facing label for the category.
  String get displayName {
    switch (this) {
      case ListingCategory.goods:
        return 'Goods';
      case ListingCategory.services:
        return 'Services';
      case ListingCategory.digital:
        return 'Digital';
      case ListingCategory.automotive:
        return 'Automotive';
      case ListingCategory.electronics:
        return 'Electronics';
      case ListingCategory.fashion:
        return 'Fashion';
      case ListingCategory.home:
        return 'Home';
      case ListingCategory.sports:
        return 'Sports';
    }
  }
}

/// Possible lifecycle states for a listing.
enum ListingStatus { active, traded, expired, deleted }

extension ListingStatusX on ListingStatus {
  /// Convert a backend string into a [ListingStatus].
  static ListingStatus fromName(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return ListingStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => ListingStatus.active,
    );
  }
}

/// Basic metadata describing the owner of a listing.
class ListingOwner {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? avatarUrl;

  const ListingOwner({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.avatarUrl,
  });

  /// Preferred display name with graceful fallbacks.
  String get displayName {
    final username = this.username?.trim() ?? '';
    if (username.isNotEmpty) {
      return username;
    }

    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    final combined = [first, last].where((value) => value.isNotEmpty).join(' ');
    if (combined.isNotEmpty) {
      return combined;
    }

    final emailAddress = email?.trim() ?? '';
    if (emailAddress.isNotEmpty) {
      return emailAddress.contains('@')
          ? emailAddress.split('@').first
          : emailAddress;
    }

    return 'SwapWing Trader';
  }

  /// Initials derived from the display name. Used for avatars.
  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) {
      return 'S';
    }

    final parts = name.split(RegExp(r'\s+')).where((value) => value.isNotEmpty).toList();
    if (parts.isEmpty) {
      return name.substring(0, 1).toUpperCase();
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    final firstInitial = parts.first.substring(0, 1).toUpperCase();
    final lastInitial = parts.last.substring(0, 1).toUpperCase();
    final combined = '$firstInitial$lastInitial';
    return combined.trim().isEmpty ? 'S' : combined;
  }

  factory ListingOwner.fromApi(Map<String, dynamic> json) {
    final id = (json['user_id'] ?? json['id'] ?? '').toString();
    return ListingOwner(
      id: id.isEmpty ? 'unknown' : id,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['profile_image_url'] as String?,
    );
  }

  factory ListingOwner.fromUser(SwapWingUser user) {
    return ListingOwner(
      id: user.id,
      email: user.email,
      username: user.username,
      avatarUrl: user.profileImageUrl,
    );
  }
}

/// Canonical representation of a listing shown throughout the Flutter client.
class SwapListing {
  final String id;
  final String ownerId;
  final ListingOwner? owner;
  final String title;
  final String description;
  final List<String> imageUrls;
  final ListingCategory category;
  final List<String> tags;
  final double? estimatedValue;
  final bool isTradeUpEligible;
  final String? location;
  final ListingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SwapListing({
    required this.id,
    required this.ownerId,
    this.owner,
    required this.title,
    required this.description,
    this.imageUrls = const [],
    required this.category,
    this.tags = const [],
    this.estimatedValue,
    this.isTradeUpEligible = false,
    this.location,
    this.status = ListingStatus.active,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convenience accessor for the first image url.
  String? get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : null;

  SwapListing copyWith({
    String? id,
    String? ownerId,
    ListingOwner? owner,
    String? title,
    String? description,
    List<String>? imageUrls,
    ListingCategory? category,
    List<String>? tags,
    double? estimatedValue,
    bool? isTradeUpEligible,
    String? location,
    ListingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SwapListing(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      isTradeUpEligible: isTradeUpEligible ?? this.isTradeUpEligible,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SwapListing.fromApi(Map<String, dynamic> json) {
    final ownerJson = json['owner'];
    final owner = ownerJson is Map<String, dynamic>
        ? ListingOwner.fromApi(ownerJson)
        : null;

    final media = json['media'];
    final mediaUrls = <String>[];
    if (media is List) {
      for (final item in media) {
        if (item is Map<String, dynamic>) {
          final url = (item['url'] ?? item['external_url'] ?? '').toString();
          if (url.isNotEmpty) {
            mediaUrls.add(url);
          }
        }
      }
    }

    if (mediaUrls.isEmpty) {
      final directUrls = json['image_urls'];
      if (directUrls is List) {
        mediaUrls.addAll(
          directUrls
              .map((value) => value?.toString() ?? '')
              .where((value) => value.isNotEmpty),
        );
      } else {
        final singleUrl = json['image_url']?.toString();
        if (singleUrl != null && singleUrl.isNotEmpty) {
          mediaUrls.add(singleUrl);
        }
      }
    }

    final tagsValue = json['tags'];
    final parsedTags = <String>[];
    if (tagsValue is List) {
      parsedTags.addAll(
        tagsValue.map((tag) => tag?.toString() ?? '').where((tag) => tag.isNotEmpty),
      );
    } else if (tagsValue is String && tagsValue.trim().isNotEmpty) {
      parsedTags.add(tagsValue.trim());
    }

    final estimatedRaw = json['estimated_value'];
    double? estimatedValue;
    if (estimatedRaw is num) {
      estimatedValue = estimatedRaw.toDouble();
    } else if (estimatedRaw is String && estimatedRaw.trim().isNotEmpty) {
      estimatedValue = double.tryParse(estimatedRaw);
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed.toLocal();
        }
      }
      return DateTime.now();
    }

    final createdAt = parseDate(json['created_at']);
    final updatedAtRaw = json['updated_at'];
    final updatedAt = updatedAtRaw == null ? null : parseDate(updatedAtRaw);

    final ownerId = owner?.id ?? (json['owner_id'] ?? '').toString();

    return SwapListing(
      id: (json['id'] ?? '').toString(),
      ownerId: ownerId.isEmpty ? 'unknown' : ownerId,
      owner: owner,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrls: mediaUrls,
      category: ListingCategoryX.fromName(json['category']?.toString()),
      tags: parsedTags,
      estimatedValue: estimatedValue,
      isTradeUpEligible: json['is_trade_up_eligible'] as bool? ?? false,
      location: json['location'] as String?,
      status: ListingStatusX.fromName(json['status']?.toString()),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
