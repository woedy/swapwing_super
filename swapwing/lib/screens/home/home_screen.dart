import 'package:flutter/material.dart';
import 'package:swapwing/models/listing.dart';
import 'package:swapwing/models/notification_preferences.dart';
import 'package:swapwing/screens/listings/listing_detail_screen.dart';
import 'package:swapwing/screens/settings/notification_settings_screen.dart';
import 'package:swapwing/services/analytics_service.dart';
import 'package:swapwing/services/auth_service.dart';
import 'package:swapwing/services/listing_service.dart';
import 'package:swapwing/services/push_notification_service.dart';
import 'package:swapwing/widgets/ai_suggestions_card.dart';
import 'package:swapwing/widgets/category_grid.dart';
import 'package:swapwing/widgets/listing_card.dart';
import 'package:swapwing/widgets/listing_card_skeleton.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final ListingService _listingService = const ListingService();
  final AnalyticsService _analytics = AnalyticsService.instance;

  List<SwapListing> _featuredListings = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _analytics.logEvent('home_feed_viewed');
    _loadListings();
  }

  Future<void> _handleEnableNotifications() async {
    final status = await PushNotificationService.requestPermission();
    if (!mounted) return;
    final granted = status == NotificationPermissionStatus.granted ||
        status == NotificationPermissionStatus.provisional;
    final message = granted
        ? 'Push notifications are now on. You\'ll stay in the loop on trades and challenges.'
        : 'Looks like notifications are still disabled. Try managing them from settings.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  Future<void> _loadListings({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      if (refresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
        _errorMessage = null;
      }
    });

    try {
      final listings = await _listingService.fetchListings(ordering: '-created_at');
      _analytics.logEvent(
        'home_feed_loaded',
        properties: {
          'listing_count': listings.length,
          'refresh': refresh,
        },
      );
      if (!mounted) return;
      setState(() {
        _featuredListings = listings;
        _errorMessage = null;
      });
    } on ListingServiceException catch (error) {
      _analytics.logEvent(
        'home_feed_failed',
        properties: {
          'refresh': refresh,
          'error': error.message,
        },
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _featuredListings = [];
      });
    } catch (_) {
      _analytics.logEvent(
        'home_feed_failed',
        properties: {
          'refresh': refresh,
          'error': 'unexpected_error',
        },
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = 'We could not load listings right now. Pull to refresh and try again.';
        _featuredListings = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadListings(refresh: true),
        displacement: 32,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              toolbarHeight: 80,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: user?.profileImageUrl != null
                        ? NetworkImage(user!.profileImageUrl!)
                        : null,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: user?.profileImageUrl == null
                        ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.username ?? 'Trader'}!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          'Ready to make some trades?',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: _openNotificationSettings,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    ValueListenableBuilder<NotificationPermissionStatus>(
                      valueListenable:
                          PushNotificationService.permissionStatusNotifier,
                      builder: (context, status, _) {
                        final granted = status ==
                                NotificationPermissionStatus.granted ||
                            status ==
                                NotificationPermissionStatus.provisional;
                        if (granted) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _NotificationPromptCard(
                            status: status,
                            onEnable: _handleEnableNotifications,
                            onManage: _openNotificationSettings,
                          ),
                        );
                      },
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'Search for items or services...',
                                hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                border: InputBorder.none,
                              ),
                              onTap: () => DefaultTabController.of(context)?.animateTo(1),
                            ),
                          ),
                          Icon(
                            Icons.camera_alt_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    AISuggestionsCard(),
                    SizedBox(height: 32),
                    Text(
                      'Browse Categories',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    SizedBox(height: 16),
                    CategoryGrid(),
                    SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Items',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        TextButton(
                          onPressed: () => DefaultTabController.of(context)?.animateTo(1),
                          child: Text(
                            'View All',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (_isLoading && !_isRefreshing)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const ListingCardSkeleton(),
                    childCount: 4,
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
                  child: _ErrorState(
                    message: _errorMessage!,
                    onRetry: () => _loadListings(refresh: true),
                  ),
                ),
              )
            else if (_featuredListings.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 40),
                  child: _EmptyState(onRefresh: () => _loadListings(refresh: true)),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final listing = _featuredListings[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListingCard(
                        listing: listing,
                        onTap: () {
                          _analytics.logEvent(
                            'listing_opened_from_feed',
                            properties: {
                              'listing_id': listing.id,
                              'category': listing.category.name,
                            },
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ListingDetailScreen(listing: listing),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: _featuredListings.length,
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _NotificationPromptCard extends StatelessWidget {
  final NotificationPermissionStatus status;
  final VoidCallback onEnable;
  final VoidCallback onManage;

  const _NotificationPromptCard({
    required this.status,
    required this.onEnable,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Turn on push notifications',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Never miss a trade update or challenge milestone. Enable alerts to get notified instantly.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Current status: ${status.readableLabel}',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: onEnable,
                child: const Text('Enable alerts'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onManage,
                child: const Text('Manage preferences'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: 16),
        Text(
          'No listings yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        SizedBox(height: 8),
        Text(
          'Pull down to refresh or check back soon for new swaps.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRefresh,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            side: BorderSide(color: Theme.of(context).colorScheme.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: Icon(Icons.refresh),
          label: Text('Refresh Listings'),
        ),
      ],
    );
  }
}
