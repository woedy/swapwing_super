import 'package:flutter/material.dart';
import 'package:swapwing/models/trade_journey.dart';
import 'package:swapwing/screens/social/journey_detail_screen.dart';

class TikTokJourneyFeed extends StatefulWidget {
  final List<TradeJourney> journeys;
  final int initialIndex;

  const TikTokJourneyFeed({
    super.key,
    required this.journeys,
    this.initialIndex = 0,
  });

  @override
  State<TikTokJourneyFeed> createState() => _TikTokJourneyFeedState();
}

class _TikTokJourneyFeedState extends State<TikTokJourneyFeed> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<TradeJourney> _journeys = [];

  @override
  void initState() {
    super.initState();
    _journeys = List.from(widget.journeys);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleLike(TradeJourney journey) {
    setState(() {
      final index = _journeys.indexWhere((j) => j.id == journey.id);
      if (index != -1) {
        _journeys[index] = journey.copyWith(
          isLikedByCurrentUser: !journey.isLikedByCurrentUser,
          likes: journey.isLikedByCurrentUser ? journey.likes - 1 : journey.likes + 1,
        );
      }
    });
  }

  void _onShare(TradeJourney journey) {
    setState(() {
      final index = _journeys.indexWhere((j) => j.id == journey.id);
      if (index != -1) {
        _journeys[index] = journey.copyWith(shares: journey.shares + 1);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Journey shared!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _journeys.length,
            itemBuilder: (context, index) {
              final journey = _journeys[index];
              return TikTokJourneyCard(
                journey: journey,
                onLike: () => _toggleLike(journey),
                onComment: () => _showComments(journey),
                onShare: () => _onShare(journey),
                onTapDetails: () => _openJourneyDetails(journey),
              );
            },
          ),
          
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComments(TradeJourney journey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(journey: journey),
    );
  }

  void _openJourneyDetails(TradeJourney journey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyDetailScreen(journey: journey),
      ),
    );
  }
}

class TikTokJourneyCard extends StatelessWidget {
  final TradeJourney journey;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onTapDetails;

  const TikTokJourneyCard({
    super.key,
    required this.journey,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapDetails,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background with journey progress visualization
            Positioned.fill(
              child: TikTokProgressVisualization(journey: journey),
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
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
            
            // User info at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 80,
              child: TikTokUserHeader(journey: journey),
            ),
            
            // Journey info at bottom
            Positioned(
              bottom: 100,
              left: 16,
              right: 80,
              child: TikTokJourneyInfo(journey: journey),
            ),
            
            // Action buttons on the right
            Positioned(
              bottom: 100,
              right: 16,
              child: TikTokActionButtons(
                journey: journey,
                onLike: onLike,
                onComment: onComment,
                onShare: onShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TikTokProgressVisualization extends StatelessWidget {
  final TradeJourney journey;

  const TikTokProgressVisualization({
    super.key,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  // Progress circle
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: journey.progressPercentage / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  // Center content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '\$${journey.currentValue.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${journey.progressPercentage.toStringAsFixed(0)}% to goal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              '${journey.totalSteps} trades completed',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TikTokUserHeader extends StatelessWidget {
  final TradeJourney journey;

  const TikTokUserHeader({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            journey.userName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                journey.userName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _timeAgo(journey.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.more_vert,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }
}

class TikTokJourneyInfo extends StatelessWidget {
  final TradeJourney journey;

  const TikTokJourneyInfo({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          journey.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (journey.description?.isNotEmpty == true) ...[
          SizedBox(height: 8),
          Text(
            journey.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        SizedBox(height: 12),
        // Tags
        if (journey.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            children: journey.tags.take(3).map((tag) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$tag',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class TikTokActionButtons extends StatelessWidget {
  final TradeJourney journey;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const TikTokActionButtons({
    super.key,
    required this.journey,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TikTokActionButton(
          icon: journey.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(journey.likes),
          isActive: journey.isLikedByCurrentUser,
          onTap: onLike,
        ),
        SizedBox(height: 24),
        TikTokActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(journey.comments),
          onTap: onComment,
        ),
        SizedBox(height: 24),
        TikTokActionButton(
          icon: Icons.share_outlined,
          label: _formatCount(journey.shares),
          onTap: onShare,
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class TikTokActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const TikTokActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.red : Colors.white,
              size: 28,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class CommentsBottomSheet extends StatelessWidget {
  final TradeJourney journey;

  const CommentsBottomSheet({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No comments yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Be the first to comment on this journey',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}