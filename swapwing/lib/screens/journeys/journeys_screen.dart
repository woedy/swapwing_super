import 'package:flutter/material.dart';
import 'package:swapwing/models/journey_draft.dart';
import 'package:swapwing/models/trade_journey.dart';
import 'package:swapwing/screens/journeys/journey_composer_screen.dart';
import 'package:swapwing/screens/social/journey_detail_screen.dart';
import 'package:swapwing/services/journey_service.dart';
import 'package:swapwing/services/sample_data.dart';
import 'package:swapwing/widgets/journey_card.dart';

class JourneysScreen extends StatefulWidget {
  const JourneysScreen({super.key});

  @override
  State<JourneysScreen> createState() => _JourneysScreenState();
}

class _JourneysScreenState extends State<JourneysScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final JourneyService _journeyService = const JourneyService();

  List<TradeJourney> _myJourneys = const [];
  List<JourneyDraft> _drafts = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJourneys();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJourneys({bool silently = false}) async {
    if (!silently) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _journeyService.fetchMyJourneys(),
        _journeyService.fetchDrafts(),
      ]);

      if (!mounted) return;
      setState(() {
        _myJourneys = results[0];
        _drafts = results[1];
        _isLoading = false;
      });
    } on JourneyServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshJourneys() async {
    await _loadJourneys(silently: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trade-Up Journeys',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
            onPressed: () => _openComposer(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Journeys'),
            Tab(text: 'Discover'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyJourneys(),
          _buildDiscoverJourneys(),
        ],
      ),
    );
  }

  Widget _buildMyJourneys() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadJourneys,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final children = <Widget>[];

    if (_drafts.isNotEmpty) {
      children.addAll([
        Text(
          'Drafts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        ..._drafts.map(
          (draft) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _JourneyDraftCard(
              draft: draft,
              onEdit: () => _openComposer(draft: draft),
              onPreview: () => _openDraftPreview(draft),
              onDelete: () => _deleteDraft(draft),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ]);
    }

    if (_myJourneys.isNotEmpty) {
      children.addAll([
        Text(
          'Active Journeys',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        ..._myJourneys.map(
          (journey) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: JourneyCard(journey: journey),
          ),
        ),
      ]);
    }

    if (children.isEmpty) {
      children.add(_buildEmptyState());
    }

    return RefreshIndicator(
      onRefresh: _refreshJourneys,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.timeline,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Trade-Up Journeys Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Start your first trade-up journey and watch your items grow in value!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openComposer(),
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Start your first journey'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverJourneys() {
    final featured = SampleData.getSocialJourneys().take(3).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Journey Inspiration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Get inspired by these amazing trade-up stories from our community!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Featured Journeys',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        ...featured.map(
          (journey) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: JourneyCard(journey: journey),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Marketplace Legends',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        _FeaturedJourneyCard(
          title: 'Paperclip to MacBook Pro',
          startItem: 'Paperclip',
          endItem: 'MacBook Pro',
          steps: 14,
          valueIncrease: 2499,
          imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&h=600&fit=crop',
        ),
        const SizedBox(height: 16),
        _FeaturedJourneyCard(
          title: 'Skateboard to Travel Van',
          startItem: 'Skateboard',
          endItem: 'Sprinter Van',
          steps: 11,
          valueIncrease: 4200,
          imageUrl: 'https://images.unsplash.com/photo-1519643381401-22c77e60520e?w=800&h=600&fit=crop',
        ),
      ],
    );
  }

  Future<void> _openComposer({JourneyDraft? draft}) async {
    final result = await Navigator.of(context).push<JourneyComposerResult?>(
      MaterialPageRoute(
        builder: (context) => JourneyComposerScreen(initialDraft: draft),
      ),
    );

    await _loadJourneys(silently: true);
    if (!mounted) return;
    if (result != null && result.didPublish) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Journey published!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      _tabController.animateTo(0);
    }
  }

  Future<void> _openDraftPreview(JourneyDraft draft) async {
    final preview = draft.toTradeJourney(SampleData.currentUser);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JourneyDetailScreen(journey: preview),
      ),
    );
  }

  Future<void> _deleteDraft(JourneyDraft draft) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete draft?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _journeyService.deleteDraft(draft.id);
      await _loadJourneys(silently: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draft deleted'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }
}

class _JourneyDraftCard extends StatelessWidget {
  final JourneyDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  const _JourneyDraftCard({
    required this.draft,
    required this.onEdit,
    required this.onPreview,
    required this.onDelete,
  });

  String _formatRelative(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (draft.title ?? 'Untitled Journey').trim().isEmpty
                            ? 'Untitled Journey'
                            : draft.title!.trim(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Updated ${_formatRelative(draft.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Preview draft',
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_outlined),
                ),
                IconButton(
                  tooltip: 'Continue editing',
                  onPressed: onEdit,
                  icon: const Icon(Icons.open_in_new),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (draft.description?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  draft.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _DraftStatChip(
                  icon: Icons.flag_outlined,
                  label: draft.targetValue != null
                      ? 'Goal ${_formatCurrency(draft.targetValue!)}'
                      : 'Goal pending',
                ),
                _DraftStatChip(
                  icon: Icons.timeline_outlined,
                  label: '${draft.steps.length} steps',
                ),
                if (draft.startingListing?.title != null)
                  _DraftStatChip(
                    icon: Icons.inventory_2_outlined,
                    label: draft.startingListing!.title,
                  ),
              ],
            ),
            if (draft.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: draft.normalizedTags
                    .map((tag) => Chip(label: Text('#$tag')))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune),
                  label: const Text('Edit draft'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
  }
}

class _DraftStatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DraftStatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _FeaturedJourneyCard extends StatelessWidget {
  final String title;
  final String startItem;
  final String endItem;
  final int steps;
  final double valueIncrease;
  final String imageUrl;

  const _FeaturedJourneyCard({
    required this.title,
    required this.startItem,
    required this.endItem,
    required this.steps,
    required this.valueIncrease,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$startItem → $endItem',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.timeline,
                      label: '$steps steps',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.trending_up,
                      label: '+\$${valueIncrease.toInt()}',
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
