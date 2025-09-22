import 'package:flutter/material.dart';
import 'package:swapwing/models/trade_journey.dart';
import 'package:swapwing/models/listing.dart';
import 'package:swapwing/services/sample_data.dart';

class JourneyDetailScreen extends StatefulWidget {
  final TradeJourney journey;

  const JourneyDetailScreen({super.key, required this.journey});

  @override
  State<JourneyDetailScreen> createState() => _JourneyDetailScreenState();
}

class _JourneyDetailScreenState extends State<JourneyDetailScreen> {
  late TradeJourney journey;
  List<SwapListing> _stepListings = [];

  @override
  void initState() {
    super.initState();
    journey = widget.journey;
    _loadStepListings();
  }

  void _loadStepListings() {
    // Get sample listings for the journey steps
    setState(() {
      _stepListings = SampleData.getListings().take(journey.totalSteps + 1).toList();
    });
  }

  void _toggleLike() {
    setState(() {
      journey = journey.copyWith(
        isLikedByCurrentUser: !journey.isLikedByCurrentUser,
        likes: journey.isLikedByCurrentUser ? journey.likes - 1 : journey.likes + 1,
      );
    });
  }

  void _onShare() {
    setState(() {
      journey = journey.copyWith(shares: journey.shares + 1);
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                journey.title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: JourneyProgressCircle(journey: journey),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _onShare,
                icon: Icon(Icons.share, color: Colors.white),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JourneyHeader(journey: journey),
                  SizedBox(height: 24),
                  JourneyStats(journey: journey),
                  SizedBox(height: 24),
                  JourneyDescription(journey: journey),
                  SizedBox(height: 24),
                  JourneyTags(journey: journey),
                  SizedBox(height: 24),
                  ActionRow(
                    journey: journey,
                    onLike: _toggleLike,
                    onComment: _showComments,
                    onShare: _onShare,
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Journey Steps',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  // Starting item
                  return JourneyStepCard(
                    stepNumber: 0,
                    title: 'Starting Item',
                    listing: _stepListings.isNotEmpty ? _stepListings[0] : null,
                    value: journey.startingValue,
                    isStarting: true,
                  );
                } else if (index <= journey.totalSteps) {
                  final step = journey.tradeSteps[index - 1];
                  return JourneyStepCard(
                    stepNumber: index,
                    title: 'Step $index',
                    listing: _stepListings.length > index ? _stepListings[index] : null,
                    value: step.toValue,
                    valueIncrease: step.valueIncrease,
                    date: step.completedAt,
                    notes: step.notes,
                  );
                }
                return null;
              },
              childCount: journey.totalSteps + 1,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: 32),
          ),
        ],
      ),
    );
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(journey: journey),
    );
  }
}

class JourneyProgressCircle extends StatelessWidget {
  final TradeJourney journey;

  const JourneyProgressCircle({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: journey.progressPercentage / 100,
              strokeWidth: 6,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\$${journey.currentValue.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${journey.progressPercentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
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

class JourneyHeader extends StatelessWidget {
  final TradeJourney journey;

  const JourneyHeader({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            journey.userName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                journey.userName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_timeAgo(journey.createdAt)} • ${journey.status.name.toUpperCase()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            journey.status.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class JourneyStats extends StatelessWidget {
  final TradeJourney journey;

  const JourneyStats({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: StatItem(
              label: 'Starting Value',
              value: '\$${journey.startingValue.toStringAsFixed(0)}',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: StatItem(
              label: 'Current Value',
              value: '\$${journey.currentValue.toStringAsFixed(0)}',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: StatItem(
              label: 'Target Value',
              value: '\$${journey.targetValue.toStringAsFixed(0)}',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class JourneyDescription extends StatelessWidget {
  final TradeJourney journey;

  const JourneyDescription({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    if (journey.description?.isEmpty ?? true) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Journey',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          journey.description!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class JourneyTags extends StatelessWidget {
  final TradeJourney journey;

  const JourneyTags({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    if (journey.tags.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: journey.tags.map((tag) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Text(
                '#$tag',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ActionRow extends StatelessWidget {
  final TradeJourney journey;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const ActionRow({
    super.key,
    required this.journey,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          HorizontalActionButton(
            icon: journey.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
            label: '${journey.likes} Likes',
            isActive: journey.isLikedByCurrentUser,
            onTap: onLike,
          ),
          HorizontalActionButton(
            icon: Icons.chat_bubble_outline,
            label: '${journey.comments} Comments',
            onTap: onComment,
          ),
          HorizontalActionButton(
            icon: Icons.share_outlined,
            label: '${journey.shares} Shares',
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class HorizontalActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const HorizontalActionButton({
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive 
                ? Colors.red 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isActive
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class JourneyStepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final SwapListing? listing;
  final double value;
  final double? valueIncrease;
  final DateTime? date;
  final String? notes;
  final bool isStarting;

  const JourneyStepCard({
    super.key,
    required this.stepNumber,
    required this.title,
    this.listing,
    required this.value,
    this.valueIncrease,
    this.date,
    this.notes,
    this.isStarting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Step number circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isStarting 
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  stepNumber.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (valueIncrease != null && valueIncrease! > 0) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+\$${valueIncrease!.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    listing?.title ?? 'Unknown Item',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Value: \$${value.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (date != null) ...[
                    SizedBox(height: 4),
                    Text(
                      _formatDate(date!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                  if (notes?.isNotEmpty == true) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just completed';
    }
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