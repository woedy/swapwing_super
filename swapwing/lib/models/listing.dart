enum ListingCategory { goods, services, digital, automotive, electronics, fashion, home, sports }

enum ListingStatus { active, traded, expired, deleted }

class SwapListing {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final ListingCategory category;
  final List<String> tags;
  final double estimatedValue;
  final bool isTradeUpEligible;
  final String? location;
  final ListingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SwapListing({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    this.imageUrls = const [],
    required this.category,
    this.tags = const [],
    required this.estimatedValue,
    this.isTradeUpEligible = false,
    this.location,
    this.status = ListingStatus.active,
    required this.createdAt,
    this.updatedAt,
  });

  SwapListing copyWith({
    String? id,
    String? ownerId,
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
}