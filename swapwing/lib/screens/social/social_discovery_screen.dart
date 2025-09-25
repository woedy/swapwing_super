import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swapwing/models/trade_journey.dart';
import 'package:swapwing/models/challenge.dart';
import 'package:swapwing/services/analytics_service.dart';
import 'package:swapwing/services/challenge_service.dart';
import 'package:swapwing/services/sample_data.dart';
import 'package:swapwing/screens/social/journey_detail_screen.dart';
import 'package:swapwing/screens/social/challenge_detail_screen.dart';
import 'package:swapwing/screens/social/tiktok_journey_feed.dart';

class SocialDiscoveryScreen extends StatefulWidget {
  const SocialDiscoveryScreen({super.key});

  @override
  State<SocialDiscoveryScreen> createState() => _SocialDiscoveryScreenState();
}

class _SocialDiscoveryScreenState extends State<SocialDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ChallengeService _challengeService;
  final AnalyticsService _analytics = AnalyticsService.instance;
  StreamSubscription<List<Challenge>>? _challengeSubscription;
  List<TradeJourney> _journeys = [];
  List<Challenge> _challenges = [];
  bool _isLoadingChallenges = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _challengeService = ChallengeService();
    _loadData();
    _challengeSubscription = _challengeService.watchChallenges().listen((list) {
      if (!mounted) return;
      setState(() {
        _challenges = list;
        _isLoadingChallenges = false;
      });
    });
    _analytics.logEvent('social_discovery_opened');
  }

  void _loadData() {
    setState(() {
      _journeys = SampleData.getSocialJourneys();
      _isLoadingChallenges = true;
    });
    _analytics.logEvent(
      'social_discovery_refreshed',
      properties: {'source': 'initial_load'},
    );
    _challengeService.fetchChallenges();
  }

  Future<List<Challenge>> _refreshChallenges() async {
    _analytics.logEvent(
      'social_discovery_refreshed',
      properties: {'source': 'pull_to_refresh'},
    );
    return _challengeService.fetchChallenges(refresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _challengeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Social',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Journeys'),
            Tab(text: 'Challenges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          JourneysGridView(journeys: _journeys),
          ChallengesGridView(
            challenges: _challenges,
            isLoading: _isLoadingChallenges,
            onRefresh: _refreshChallenges,
          ),
        ],
      ),
    );
  }
}

class JourneysGridView extends StatelessWidget {
  final List<TradeJourney> journeys;

  const JourneysGridView({super.key, required this.journeys});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: journeys.length,
        itemBuilder: (context, index) {
          final journey = journeys[index];
          return JourneyThumbnailCard(
            journey: journey,
            onTap: () => _openJourneyFeed(context, journey, journeys),
          );
        },
      ),
    );
  }

  void _openJourneyFeed(BuildContext context, TradeJourney journey, List<TradeJourney> allJourneys) {
    final startIndex = allJourneys.indexOf(journey);
    AnalyticsService.instance.logEvent(
      'journey_social_feed_opened',
      properties: {
        'journey_id': journey.id,
        'position': startIndex,
      },
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TikTokJourneyFeed(
          journeys: allJourneys,
          initialIndex: startIndex,
        ),
      ),
    );
  }
}

class ChallengesGridView extends StatelessWidget {
  final List<Challenge> challenges;
  final bool isLoading;
  final Future<List<Challenge>> Function()? onRefresh;

  const ChallengesGridView({
    super.key,
    required this.challenges,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (onRefresh == null) {
      return content;
    }

    return RefreshIndicator(
      onRefresh: () async {
        await onRefresh?.call();
      },
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return ListView(
        padding: EdgeInsets.symmetric(vertical: 80),
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (challenges.isEmpty) {
      return ListView(
        padding: EdgeInsets.symmetric(vertical: 80, horizontal: 32),
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              SizedBox(height: 16),
              Text(
                'Challenges are coming soon!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 8),
              Text(
                'Check back shortly as the community kicks off new trading quests.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.all(16),
      physics: AlwaysScrollableScrollPhysics(),
      children: [
        Text(
          'Active Challenges',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 16),
        ...challenges.map(
          (challenge) => Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: ChallengeCard(
              challenge: challenge,
              onTap: () => _openChallengeDetail(context, challenge),
            ),
          ),
        ),
      ],
    );
  }

  void _openChallengeDetail(BuildContext context, Challenge challenge) {
    AnalyticsService.instance.logEvent(
      'challenge_card_opened',
      properties: {
        'challenge_id': challenge.id,
        'status': challenge.status.name,
      },
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeDetailScreen(challenge: challenge),
      ),
    );
  }
}

class JourneyThumbnailCard extends StatelessWidget {
  final TradeJourney journey;
  final VoidCallback onTap;

  const JourneyThumbnailCard({
    super.key,
    required this.journey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern or image
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CircularProgressIndicator(
                            value: journey.progressPercentage / 100,
                            strokeWidth: 4,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        Center(
                          child: Text(
                            '\$${journey.currentValue.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // User info at top
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Text(
                      journey.userName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      journey.userName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Journey info at bottom
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    journey.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.white.withOpacity(0.8),
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${journey.likes}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white.withOpacity(0.8),
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${journey.comments}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status indicator
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(journey.status).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(journey.status),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TradeJourneyStatus status) {
    switch (status) {
      case TradeJourneyStatus.active:
        return Colors.green;
      case TradeJourneyStatus.completed:
        return Colors.blue;
      case TradeJourneyStatus.paused:
        return Colors.orange;
    }
  }

  String _getStatusText(TradeJourneyStatus status) {
    switch (status) {
      case TradeJourneyStatus.active:
        return 'Active';
      case TradeJourneyStatus.completed:
        return 'Done';
      case TradeJourneyStatus.paused:
        return 'Paused';
    }
  }
}

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.network(
                  challenge.bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Challenge info
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(challenge.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(challenge.status),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          challenge.timeRemaining,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      challenge.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${challenge.participantCount} participants',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Spacer(),
                        Text(
                          '\$${challenge.targetValue.toStringAsFixed(0)} goal',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Join/Joined indicator
              if (challenge.hasJoined)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Joined',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.active:
        return Colors.green;
      case ChallengeStatus.upcoming:
        return Colors.orange;
      case ChallengeStatus.ended:
        return Colors.grey;
    }
  }

  String _getStatusText(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.active:
        return 'LIVE';
      case ChallengeStatus.upcoming:
        return 'SOON';
      case ChallengeStatus.ended:
        return 'ENDED';
    }
  }
}