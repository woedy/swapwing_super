import 'package:swapwing/models/listing.dart';
import 'package:swapwing/models/journey_draft.dart';
import 'package:swapwing/models/trade_journey.dart';
import 'package:swapwing/models/chat_message.dart';
import 'package:swapwing/models/challenge.dart';
import 'package:swapwing/models/user.dart';

class SampleData {
  static final SwapWingUser currentUser = SwapWingUser(
    id: 'user_001',
    username: 'alex_trader',
    email: 'alex@example.com',
    profileImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
    bio: 'Passionate trader looking for unique items and experiences! 🔄',
    location: 'San Francisco, CA',
    tradeRadius: 50.0,
    preferredCategories: ['electronics', 'fashion', 'sports'],
    trustScore: 4.2,
    totalTrades: 12,
    isVerified: true,
    createdAt: DateTime.now().subtract(Duration(days: 90)),
  );

  static ListingOwner _ownerFor(String userId) {
    final users = sampleUsers;
    final match = users.firstWhere(
      (user) => user.id == userId,
      orElse: () => currentUser,
    );
    return ListingOwner.fromUser(match);
  }

  static final List<SwapListing> sampleListings = [
    SwapListing(
      id: 'listing_my_001',
      ownerId: currentUser.id,
      owner: ListingOwner.fromUser(currentUser),
      title: 'Starter Acoustic Guitar',
      description: 'Six-string acoustic guitar with warm tone. Looking to trade up for studio equipment.',
      imageUrls: ['https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&h=300&fit=crop'],
      category: ListingCategory.goods,
      tags: ['music', 'guitar', 'trade-up'],
      estimatedValue: 220.0,
      isTradeUpEligible: true,
      location: 'San Francisco, CA',
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    SwapListing(
      id: 'listing_001',
      ownerId: 'user_002',
      owner: _ownerFor('user_002'),
      title: 'Vintage Polaroid Camera',
      description: 'Classic instant camera in excellent condition. Perfect for photography enthusiasts!',
      imageUrls: ['https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=400&h=300&fit=crop'],
      category: ListingCategory.electronics,
      tags: ['vintage', 'camera', 'photography', 'retro'],
      estimatedValue: 180.0,
      isTradeUpEligible: true,
      location: 'San Francisco, CA',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    SwapListing(
      id: 'listing_002',
      ownerId: 'user_003',
      owner: _ownerFor('user_003'),
      title: 'Designer Leather Jacket',
      description: 'Premium leather jacket, size Medium. Barely worn, from a smoke-free home.',
      imageUrls: ['https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400&h=300&fit=crop'],
      category: ListingCategory.fashion,
      tags: ['leather', 'jacket', 'designer', 'medium'],
      estimatedValue: 320.0,
      isTradeUpEligible: true,
      location: 'Oakland, CA',
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    SwapListing(
      id: 'listing_003',
      ownerId: 'user_004',
      owner: _ownerFor('user_004'),
      title: 'Professional Guitar Lessons',
      description: 'Learn guitar from a certified instructor. 4 session package available for trade!',
      imageUrls: ['https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=300&fit=crop'],
      category: ListingCategory.services,
      tags: ['music', 'lessons', 'guitar', 'education'],
      estimatedValue: 200.0,
      location: 'Berkeley, CA',
      createdAt: DateTime.now().subtract(Duration(hours: 8)),
    ),
    SwapListing(
      id: 'listing_004',
      ownerId: 'user_005',
      owner: _ownerFor('user_005'),
      title: 'Gaming Mechanical Keyboard',
      description: 'RGB backlit mechanical keyboard with blue switches. Great for gaming and typing.',
      imageUrls: ['https://images.unsplash.com/photo-1541140532154-b024d705b90a?w=400&h=300&fit=crop'],
      category: ListingCategory.electronics,
      tags: ['gaming', 'keyboard', 'mechanical', 'rgb'],
      estimatedValue: 150.0,
      isTradeUpEligible: true,
      location: 'Palo Alto, CA',
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    SwapListing(
      id: 'listing_005',
      ownerId: 'user_006',
      owner: _ownerFor('user_006'),
      title: 'Yoga Classes Package',
      description: '10-class package at premium studio. Perfect for wellness enthusiasts!',
      imageUrls: ['https://images.unsplash.com/photo-1506629905607-24b420c1b21c?w=400&h=300&fit=crop'],
      category: ListingCategory.services,
      tags: ['yoga', 'wellness', 'fitness', 'health'],
      estimatedValue: 180.0,
      location: 'San Jose, CA',
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
  ];

  static void addListing(SwapListing listing) {
    sampleListings.removeWhere((existing) => existing.id == listing.id);
    sampleListings.insert(0, listing);
  }

  static SwapListing? findListingById(String id) {
    if (id.isEmpty) return null;
    try {
      return sampleListings.firstWhere((listing) => listing.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<SwapListing> getListingsForUser(String userId) {
    return sampleListings.where((listing) => listing.ownerId == userId).toList();
  }

  static final List<TradeJourney> sampleJourneys = [
    TradeJourney(
      id: 'journey_001',
      userId: 'user_001',
      userName: 'alex_trader',
      title: 'Paperclip to iPhone',
      description: 'Starting with a simple paperclip, aiming for an iPhone!',
      startingListingId: 'listing_start_001',
      startingValue: 0.10,
      targetValue: 800.0,
      tradeSteps: [
        TradeStep(
          id: 'step_001',
          fromListingId: 'listing_start_001',
          toListingId: 'listing_step_001',
          fromValue: 0.10,
          toValue: 5.0,
          completedAt: DateTime.now().subtract(Duration(days: 30)),
          notes: 'Traded paperclip for pen',
        ),
        TradeStep(
          id: 'step_002',
          fromListingId: 'listing_step_001',
          toListingId: 'listing_step_002',
          fromValue: 5.0,
          toValue: 25.0,
          completedAt: DateTime.now().subtract(Duration(days: 20)),
          notes: 'Traded pen for notebook set',
        ),
      ],
      createdAt: DateTime.now().subtract(Duration(days: 35)),
      likes: 24,
      comments: 8,
      shares: 5,
      tags: ['paperclip', 'challenge', 'trading', 'iphone'],
    ),
  ];

  static List<TradeJourney> getSocialJourneys() {
    final users = sampleUsers;
    final journeys = <TradeJourney>[];
    
    // Create diverse social journeys for the feed
    journeys.addAll([
      TradeJourney(
        id: 'social_journey_001',
        userId: users[0].id,
        userName: users[0].username,
        userAvatar: users[0].profileImageUrl,
        title: 'Vintage Camera to MacBook Journey',
        description: 'Started with my grandfather\'s old camera. Goal: Get a MacBook Pro for my design work! 📷➡️💻',
        startingListingId: 'listing_001',
        startingValue: 180.0,
        targetValue: 2500.0,
        status: TradeJourneyStatus.active,
        tradeSteps: [
          TradeStep(
            id: 'step_social_001',
            fromListingId: 'listing_001',
            toListingId: 'listing_002',
            fromValue: 180.0,
            toValue: 320.0,
            completedAt: DateTime.now().subtract(Duration(days: 15)),
            notes: 'Camera for leather jacket - great condition!',
          ),
          TradeStep(
            id: 'step_social_002',
            fromListingId: 'listing_002',
            toListingId: 'listing_003',
            fromValue: 320.0,
            toValue: 450.0,
            completedAt: DateTime.now().subtract(Duration(days: 8)),
            notes: 'Jacket for professional headphones',
          ),
          TradeStep(
            id: 'step_social_003',
            fromListingId: 'listing_003',
            toListingId: 'listing_004',
            fromValue: 450.0,
            toValue: 680.0,
            completedAt: DateTime.now().subtract(Duration(days: 3)),
            notes: 'Headphones for vintage guitar',
          ),
        ],
        createdAt: DateTime.now().subtract(Duration(days: 20)),
        likes: 342,
        comments: 56,
        shares: 23,
        isLikedByCurrentUser: true,
        tags: ['vintage', 'camera', 'macbook', 'design', 'trading'],
      ),
      
      TradeJourney(
        id: 'social_journey_002',
        userId: users[1].id,
        userName: users[1].username,
        userAvatar: users[1].profileImageUrl,
        title: 'Skateboard to Drone Adventure',
        description: 'Trading my old skateboard hoping to get a professional drone for aerial photography! 🛹➡️🚁',
        startingListingId: 'listing_005',
        startingValue: 120.0,
        targetValue: 1200.0,
        status: TradeJourneyStatus.active,
        tradeSteps: [
          TradeStep(
            id: 'step_social_004',
            fromListingId: 'listing_005',
            toListingId: 'listing_006',
            fromValue: 120.0,
            toValue: 200.0,
            completedAt: DateTime.now().subtract(Duration(days: 12)),
            notes: 'Skateboard for art supplies - artist needed them!',
          ),
          TradeStep(
            id: 'step_social_005',
            fromListingId: 'listing_006',
            toListingId: 'listing_007',
            fromValue: 200.0,
            toValue: 340.0,
            completedAt: DateTime.now().subtract(Duration(days: 6)),
            notes: 'Art supplies for vintage watch',
          ),
        ],
        createdAt: DateTime.now().subtract(Duration(days: 18)),
        likes: 189,
        comments: 34,
        shares: 12,
        isLikedByCurrentUser: false,
        tags: ['skateboard', 'drone', 'photography', 'adventure'],
      ),
      
      TradeJourney(
        id: 'social_journey_003',
        userId: users[2].id,
        userName: users[2].username,
        userAvatar: users[2].profileImageUrl,
        title: 'Book Collection to Travel Fund',
        description: 'Trading my entire book collection to fund a trip to Japan! Each trade gets me closer to my dream ✈️📚',
        startingListingId: 'listing_008',
        startingValue: 300.0,
        targetValue: 2000.0,
        status: TradeJourneyStatus.completed,
        tradeSteps: [
          TradeStep(
            id: 'step_social_006',
            fromListingId: 'listing_008',
            toListingId: 'listing_009',
            fromValue: 300.0,
            toValue: 480.0,
            completedAt: DateTime.now().subtract(Duration(days: 25)),
            notes: 'Books for gaming console',
          ),
          TradeStep(
            id: 'step_social_007',
            fromListingId: 'listing_009',
            toListingId: 'listing_010',
            fromValue: 480.0,
            toValue: 750.0,
            completedAt: DateTime.now().subtract(Duration(days: 18)),
            notes: 'Gaming console for laptop',
          ),
          TradeStep(
            id: 'step_social_008',
            fromListingId: 'listing_010',
            toListingId: 'listing_011',
            fromValue: 750.0,
            toValue: 1200.0,
            completedAt: DateTime.now().subtract(Duration(days: 10)),
            notes: 'Laptop for professional camera',
          ),
          TradeStep(
            id: 'step_social_009',
            fromListingId: 'listing_011',
            toListingId: 'listing_012',
            fromValue: 1200.0,
            toValue: 2000.0,
            completedAt: DateTime.now().subtract(Duration(days: 2)),
            notes: 'Camera sold for cash - Japan here I come!',
          ),
        ],
        completedAt: DateTime.now().subtract(Duration(days: 2)),
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        likes: 892,
        comments: 127,
        shares: 64,
        isLikedByCurrentUser: true,
        tags: ['books', 'travel', 'japan', 'completed', 'success'],
      ),
      
      TradeJourney(
        id: 'social_journey_004',
        userId: users[3].id,
        userName: users[3].username,
        userAvatar: users[3].profileImageUrl,
        title: 'Guitar Lessons to Studio Equipment',
        description: 'Trading guitar lessons for studio gear. Building my home recording setup one trade at a time! 🎸🎵',
        startingListingId: 'listing_013',
        startingValue: 60.0,
        targetValue: 1500.0,
        status: TradeJourneyStatus.active,
        tradeSteps: [
          TradeStep(
            id: 'step_social_010',
            fromListingId: 'listing_013',
            toListingId: 'listing_014',
            fromValue: 60.0,
            toValue: 150.0,
            completedAt: DateTime.now().subtract(Duration(days: 14)),
            notes: 'Lessons for vintage vinyl collection',
          ),
          TradeStep(
            id: 'step_social_011',
            fromListingId: 'listing_014',
            toListingId: 'listing_015',
            fromValue: 150.0,
            toValue: 280.0,
            completedAt: DateTime.now().subtract(Duration(days: 7)),
            notes: 'Vinyl for audio interface',
          ),
        ],
        createdAt: DateTime.now().subtract(Duration(days: 16)),
        likes: 156,
        comments: 28,
        shares: 15,
        isLikedByCurrentUser: false,
        tags: ['guitar', 'music', 'studio', 'lessons', 'audio'],
      ),
      
      TradeJourney(
        id: 'social_journey_005',
        userId: users[0].id,
        userName: users[0].username,
        userAvatar: users[0].profileImageUrl,
        title: 'Paperclip Challenge 2024',
        description: 'The classic! Starting with a red paperclip, targeting a house. Let\'s see how far I can go! 📎🏠',
        startingListingId: 'listing_paperclip',
        startingValue: 0.01,
        targetValue: 50000.0,
        status: TradeJourneyStatus.active,
        tradeSteps: [
          TradeStep(
            id: 'step_paperclip_001',
            fromListingId: 'listing_paperclip',
            toListingId: 'listing_pen',
            fromValue: 0.01,
            toValue: 2.0,
            completedAt: DateTime.now().subtract(Duration(days: 5)),
            notes: 'Paperclip for fancy pen - first step!',
          ),
        ],
        createdAt: DateTime.now().subtract(Duration(days: 6)),
        likes: 45,
        comments: 12,
        shares: 8,
        isLikedByCurrentUser: false,
        tags: ['paperclip', 'challenge', 'classic', 'ambitious'],
      ),
    ]);
    
    return journeys;
  }

  static List<SwapListing> getListings() {
    return sampleListings;
  }

  static void addJourney(TradeJourney journey) {
    sampleJourneys.removeWhere((existing) => existing.id == journey.id);
    sampleJourneys.insert(0, journey);
  }

  static List<TradeJourney> getJourneysForUser(String userId) {
    return sampleJourneys.where((journey) => journey.userId == userId).toList();
  }

  static final List<JourneyDraft> _journeyDrafts = [];

  static List<JourneyDraft> getJourneyDrafts() {
    final drafts = List<JourneyDraft>.from(_journeyDrafts);
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts;
  }

  static void saveJourneyDraft(JourneyDraft draft) {
    _journeyDrafts.removeWhere((existing) => existing.id == draft.id);
    _journeyDrafts.add(draft);
    _journeyDrafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static void removeJourneyDraft(String id) {
    _journeyDrafts.removeWhere((draft) => draft.id == id);
  }

  static List<SwapWingUser> get sampleUsers => [
    SwapWingUser(
      id: 'user_002',
      username: 'photo_enthusiast',
      email: 'photo@example.com',
      profileImageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b05b?w=150&h=150&fit=crop&crop=face',
      bio: 'Photography lover collecting vintage cameras 📷',
      location: 'San Francisco, CA',
      trustScore: 4.8,
      totalTrades: 23,
      isVerified: true,
      createdAt: DateTime.now().subtract(Duration(days: 180)),
    ),
    SwapWingUser(
      id: 'user_003',
      username: 'fashion_forward',
      email: 'fashion@example.com',
      profileImageUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      bio: 'Style enthusiast trading designer pieces ✨',
      location: 'Oakland, CA',
      trustScore: 4.6,
      totalTrades: 18,
      isVerified: true,
      createdAt: DateTime.now().subtract(Duration(days: 120)),
    ),
    SwapWingUser(
      id: 'user_004',
      username: 'music_maestro',
      email: 'music@example.com',
      profileImageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
      bio: 'Music teacher sharing skills for unique items 🎸',
      location: 'Berkeley, CA',
      trustScore: 4.9,
      totalTrades: 31,
      isVerified: true,
      createdAt: DateTime.now().subtract(Duration(days: 200)),
    ),
    SwapWingUser(
      id: 'user_005',
      username: 'book_wanderer',
      email: 'books@example.com',
      profileImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      bio: 'Bookworm trading reads for travel experiences 📚✈️',
      location: 'San Jose, CA',
      trustScore: 4.7,
      totalTrades: 19,
      isVerified: true,
      createdAt: DateTime.now().subtract(Duration(days: 150)),
    ),
    SwapWingUser(
      id: 'user_006',
      username: 'wellness_guru',
      email: 'wellness@example.com',
      profileImageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&h=150&fit=crop&crop=face',
      bio: 'Helping the community stay mindful and active 🧘',
      location: 'San Jose, CA',
      trustScore: 4.5,
      totalTrades: 11,
      isVerified: true,
      createdAt: DateTime.now().subtract(Duration(days: 80)),
    ),
  ];

  static List<String> get categories => [
    'Electronics',
    'Fashion',
    'Home & Garden',
    'Sports & Outdoors',
    'Books & Media',
    'Automotive',
    'Services',
    'Digital Items',
  ];

  static List<String> get trendingTags => [
    'vintage',
    'designer',
    'handmade',
    'collectible',
    'tech',
    'gaming',
    'fitness',
    'art',
  ];

  static List<Challenge> getSampleChallenges() {
    return [
      Challenge(
        id: 'challenge_001',
        title: 'Paperclip to House Challenge',
        description: 'The ultimate trading challenge! Start with a paperclip and work your way up to a house through strategic trades.',
        startItem: 'Red Paperclip',
        goalItem: 'House',
        targetValue: 50000.0,
        startDate: DateTime.now().subtract(Duration(days: 30)),
        endDate: DateTime.now().add(Duration(days: 335)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=300&h=300&fit=crop',
        bannerUrl: 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=800&h=400&fit=crop',
        rules: [
          'Start with the provided paperclip item',
          'Each trade must increase item value',
          'No cash additions allowed',
          'Document each trade with photos',
          'Must complete within 1 year'
        ],
        participantCount: 1247,
        isActive: true,
        hasJoined: false,
        prize: 'Winner gets \$5,000 cash bonus + SwapWing Premium for life',
        topParticipants: [
          ChallengeParticipant(
            userId: 'user_002',
            userName: 'photo_enthusiast',
            avatarUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b05b?w=150&h=150&fit=crop&crop=face',
            currentValue: 2340.0,
            rank: 1,
            journeyId: 'journey_challenge_001',
            tradesCompleted: 12,
            joinedAt: DateTime.now().subtract(Duration(days: 25)),
            lastTradeAt: DateTime.now().subtract(Duration(hours: 6)),
          ),
          ChallengeParticipant(
            userId: 'user_003',
            userName: 'fashion_forward',
            avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
            currentValue: 1890.0,
            rank: 2,
            journeyId: 'journey_challenge_002',
            tradesCompleted: 9,
            joinedAt: DateTime.now().subtract(Duration(days: 20)),
            lastTradeAt: DateTime.now().subtract(Duration(hours: 18)),
          ),
          ChallengeParticipant(
            userId: 'user_004',
            userName: 'music_maestro',
            avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
            currentValue: 1654.0,
            rank: 3,
            journeyId: 'journey_challenge_003',
            tradesCompleted: 8,
            joinedAt: DateTime.now().subtract(Duration(days: 18)),
            lastTradeAt: DateTime.now().subtract(Duration(days: 1)),
          ),
        ],
        tags: ['paperclip', 'ultimate', 'house', 'legendary'],
        createdBy: 'SwapWing',
        status: ChallengeStatus.active,
      ),
      
      Challenge(
        id: 'challenge_002',
        title: 'Vintage Camera Quest',
        description: 'Trade your way to a professional vintage camera collection worth \$3000+. Perfect for photography enthusiasts!',
        startItem: 'Digital Photo Frame',
        goalItem: 'Vintage Camera Collection',
        targetValue: 3000.0,
        startDate: DateTime.now().subtract(Duration(days: 15)),
        endDate: DateTime.now().add(Duration(days: 75)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=300&h=300&fit=crop',
        bannerUrl: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=800&h=400&fit=crop',
        rules: [
          'Start with provided digital photo frame',
          'Focus on photography-related items',
          'Must end with vintage camera gear',
          'Share photography tips along the way'
        ],
        participantCount: 543,
        isActive: true,
        hasJoined: true,
        prize: 'Professional photography workshop + camera accessories',
        topParticipants: [
          ChallengeParticipant(
            userId: 'user_005',
            userName: 'book_wanderer',
            avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
            currentValue: 890.0,
            rank: 1,
            journeyId: 'journey_camera_001',
            tradesCompleted: 4,
            joinedAt: DateTime.now().subtract(Duration(days: 12)),
            lastTradeAt: DateTime.now().subtract(Duration(hours: 3)),
          ),
        ],
        tags: ['photography', 'vintage', 'camera', 'collection'],
        createdBy: 'SwapWing',
        status: ChallengeStatus.active,
        currentUserProgress: ChallengeParticipant(
          userId: currentUser.id,
          userName: currentUser.username,
          avatarUrl: currentUser.profileImageUrl ??
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          currentValue: 540.0,
          rank: 4,
          journeyId: 'journey_camera_self',
          tradesCompleted: 3,
          joinedAt: DateTime.now().subtract(Duration(days: 12)),
          lastTradeAt: DateTime.now().subtract(Duration(hours: 12)),
        ),
      ),

      Challenge(
        id: 'challenge_003',
        title: 'Tech Startup Kit Challenge',
        description: 'Build a complete tech startup kit through strategic trades. From basic tools to professional equipment!',
        startItem: 'Basic Calculator',
        goalItem: 'Complete Tech Setup',
        targetValue: 2500.0,
        startDate: DateTime.now().add(Duration(days: 7)),
        endDate: DateTime.now().add(Duration(days: 97)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=300&h=300&fit=crop',
        bannerUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800&h=400&fit=crop',
        rules: [
          'Start with the basic calculator provided',
          'Focus on tech and productivity items',
          'Build towards complete workspace setup',
          'Share entrepreneurship tips'
        ],
        participantCount: 89,
        isActive: false,
        hasJoined: false,
        prize: 'Startup mentorship program + \$1,000 funding',
        topParticipants: [],
        tags: ['tech', 'startup', 'productivity', 'workspace'],
        createdBy: 'TechHub',
        status: ChallengeStatus.upcoming,
      ),

      Challenge(
        id: 'challenge_004',
        title: 'Artist\'s Dream Studio',
        description: 'Create your perfect art studio through trades. From basic supplies to professional equipment!',
        startItem: 'Set of Pencils',
        goalItem: 'Professional Art Studio',
        targetValue: 1800.0,
        startDate: DateTime.now().subtract(Duration(days: 45)),
        endDate: DateTime.now().subtract(Duration(days: 5)),
        thumbnailUrl: 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=300&h=300&fit=crop',
        bannerUrl: 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=800&h=400&fit=crop',
        rules: [
          'Started with pencil set',
          'Focus on art supplies and equipment',
          'Share artwork created during challenge',
          'Build complete studio setup'
        ],
        participantCount: 276,
        isActive: false,
        hasJoined: false,
        prize: 'Art exhibition opportunity + premium art supplies',
        topParticipants: [
          ChallengeParticipant(
            userId: 'user_003',
            userName: 'fashion_forward',
            avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
            currentValue: 1800.0,
            rank: 1,
            journeyId: 'journey_art_winner',
            tradesCompleted: 11,
            joinedAt: DateTime.now().subtract(Duration(days: 40)),
            lastTradeAt: DateTime.now().subtract(Duration(days: 5)),
          ),
        ],
        tags: ['art', 'studio', 'creative', 'completed'],
        createdBy: 'ArtCommunity',
        status: ChallengeStatus.ended,
      ),
    ];
  }

  static Map<String, List<ChallengeProgressUpdate>> getChallengeUpdates() {
    final now = DateTime.now();
    return {
      'challenge_001': [
        ChallengeProgressUpdate(
          id: 'update_001',
          challengeId: 'challenge_001',
          userId: 'user_002',
          userName: 'photo_enthusiast',
          avatarUrl:
              'https://images.unsplash.com/photo-1494790108755-2616b612b05b?w=150&h=150&fit=crop&crop=face',
          previousValue: 2100.0,
          newValue: 2340.0,
          tradesCompleted: 12,
          message: 'Closed a trade for a refurbished DSLR kit worth \$2340.',
          timestamp: now.subtract(Duration(hours: 6)),
        ),
        ChallengeProgressUpdate(
          id: 'update_002',
          challengeId: 'challenge_001',
          userId: 'user_003',
          userName: 'fashion_forward',
          avatarUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          previousValue: 1700.0,
          newValue: 1890.0,
          tradesCompleted: 9,
          message: 'Swapped couture jacket set for a limited edition sneaker drop.',
          timestamp: now.subtract(Duration(hours: 18)),
        ),
      ],
      'challenge_002': [
        ChallengeProgressUpdate(
          id: 'update_003',
          challengeId: 'challenge_002',
          userId: currentUser.id,
          userName: currentUser.username,
          avatarUrl: currentUser.profileImageUrl ??
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          previousValue: 420.0,
          newValue: 540.0,
          tradesCompleted: 3,
          message: 'Documented a swap for a vintage Canon AE-1 body in mint condition.',
          timestamp: now.subtract(Duration(hours: 12)),
        ),
        ChallengeProgressUpdate(
          id: 'update_004',
          challengeId: 'challenge_002',
          userId: 'user_005',
          userName: 'book_wanderer',
          avatarUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          previousValue: 720.0,
          newValue: 890.0,
          tradesCompleted: 4,
          message: 'Secured a darkroom equipment bundle from a local studio closeout.',
          timestamp: now.subtract(Duration(hours: 3)),
        ),
      ],
      'challenge_004': [
        ChallengeProgressUpdate(
          id: 'update_005',
          challengeId: 'challenge_004',
          userId: 'user_003',
          userName: 'fashion_forward',
          avatarUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          previousValue: 1500.0,
          newValue: 1800.0,
          tradesCompleted: 11,
          message: 'Final trade locked in a gallery-quality lighting rig to complete the studio.',
          timestamp: now.subtract(Duration(days: 5)),
        ),
      ],
    };
  }
}