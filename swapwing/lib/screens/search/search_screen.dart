import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swapwing/models/listing.dart';
import 'package:swapwing/screens/listings/listing_detail_screen.dart';
import 'package:swapwing/services/analytics_service.dart';
import 'package:swapwing/services/listing_service.dart';
import 'package:swapwing/widgets/listing_card.dart';
import 'package:swapwing/widgets/listing_card_skeleton.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

enum _SortOption { recent, valueLowToHigh, valueHighToLow }

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final ListingService _listingService = const ListingService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  final AnalyticsService _analytics = AnalyticsService.instance;

  ListingCategory? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 1000);
  bool _tradeUpOnly = false;
  _SortOption _sortOption = _SortOption.recent;

  bool _showFilters = false;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasSearched = false;
  String? _errorMessage;
  List<SwapListing> _results = [];

  @override
  void initState() {
    super.initState();
    _analytics.logEvent('search_viewed');
    _fetchListings(triggerSearchFlag: false);
  }

  Future<void> _fetchListings({bool triggerSearchFlag = true}) async {
    final query = _searchController.text.trim();
    final hasQuery = query.isNotEmpty;

    if (!mounted) return;
    setState(() {
      _isLoading = !triggerSearchFlag;
      _isRefreshing = triggerSearchFlag;
      _errorMessage = null;
      if (triggerSearchFlag) {
        _hasSearched = hasQuery || _selectedCategory != null || _tradeUpOnly;
      }
    });

    try {
      final listings = await _listingService.fetchListings(
        search: hasQuery ? query : null,
        categories: _selectedCategory != null ? [_selectedCategory!] : null,
        tradeUpEligible: _tradeUpOnly ? true : null,
        minValue: _priceRange.start > 0 ? _priceRange.start : null,
        maxValue: _priceRange.end < 1000 ? _priceRange.end : null,
        ordering: _mapSortToOrdering(_sortOption),
      );
      _analytics.logEvent(
        'search_results_loaded',
        properties: {
          'query': hasQuery ? query : null,
          'category': _selectedCategory?.name,
          'trade_up_only': _tradeUpOnly,
          'min_value': _priceRange.start > 0 ? _priceRange.start : null,
          'max_value': _priceRange.end < 1000 ? _priceRange.end : null,
          'ordering': _mapSortToOrdering(_sortOption),
          'result_count': listings.length,
          'trigger_search_flag': triggerSearchFlag,
        },
      );
      if (!mounted) return;
      setState(() {
        _results = listings;
        _errorMessage = null;
      });
    } on ListingServiceException catch (error) {
      _analytics.logEvent(
        'search_results_failed',
        properties: {
          'reason': error.message,
          'query': hasQuery ? query : null,
        },
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _results = [];
      });
    } catch (_) {
      _analytics.logEvent(
        'search_results_failed',
        properties: {
          'reason': 'unexpected_error',
          'query': hasQuery ? query : null,
        },
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load listings. Please try again.';
        _results = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  String _mapSortToOrdering(_SortOption option) {
    switch (option) {
      case _SortOption.recent:
        return '-created_at';
      case _SortOption.valueLowToHigh:
        return 'estimated_value';
      case _SortOption.valueHighToLow:
        return '-estimated_value';
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchListings(triggerSearchFlag: true);
    });
  }

  Future<void> _onRefresh() async {
    await _fetchListings(triggerSearchFlag: true);
  }

  void _toggleFilters() {
    _analytics.logEvent(
      'search_filters_toggled',
      properties: {'show_filters': !_showFilters},
    );
    setState(() => _showFilters = !_showFilters);
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    _analytics.logEvent(
      'search_filters_applied',
      properties: {
        'category': _selectedCategory?.name,
        'trade_up_only': _tradeUpOnly,
        'min_value': _priceRange.start > 0 ? _priceRange.start : null,
        'max_value': _priceRange.end < 1000 ? _priceRange.end : null,
      },
    );
    _fetchListings(triggerSearchFlag: true);
  }

  void _updateSort(_SortOption option) {
    Navigator.pop(context);
    if (_sortOption != option) {
      setState(() => _sortOption = option);
      _analytics.logEvent(
        'search_sort_changed',
        properties: {'ordering': _mapSortToOrdering(option)},
      );
      _fetchListings(triggerSearchFlag: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            decoration: InputDecoration(
                              hintText: 'Search items, services, or keywords...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              border: InputBorder.none,
                            ),
                            textInputAction: TextInputAction.search,
                            onChanged: _onSearchChanged,
                            onSubmitted: (_) => _fetchListings(triggerSearchFlag: true),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.camera_alt_outlined,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Image search coming soon!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleFilters,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                          label: Text(
                            'Filters',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showSortBottomSheet(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            side: BorderSide(color: Theme.of(context).colorScheme.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(Icons.sort, color: Theme.of(context).colorScheme.onSurface),
                          label: Text(
                            'Sort',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: _showFilters ? 220 : 0,
              child: _showFilters ? _buildFilterPanel() : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: _buildResults(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _priceRange = const RangeValues(0, 1000);
                    _tradeUpOnly = false;
                  });
                  _fetchListings(triggerSearchFlag: true);
                },
                child: Text('Reset'),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Category',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text('All'),
                selected: _selectedCategory == null,
                onSelected: (_) {
                  setState(() => _selectedCategory = null);
                  _fetchListings(triggerSearchFlag: true);
                },
              ),
              ...ListingCategory.values.map(
                (category) => ChoiceChip(
                  label: Text(category.displayName),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                    _fetchListings(triggerSearchFlag: true);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Price Range',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000,
            divisions: 20,
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              _priceRange.end >= 1000 ? 'Any' : '\$${_priceRange.end.round()}',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
            onChangeEnd: (_) => _applyFilters(),
          ),
          Row(
            children: [
              Checkbox(
                value: _tradeUpOnly,
                onChanged: (value) {
                  setState(() => _tradeUpOnly = value ?? false);
                  _fetchListings(triggerSearchFlag: true);
                },
              ),
              Text('Trade-Up eligible only'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading && !_isRefreshing) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (context, index) => const ListingCardSkeleton(),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24),
        children: [
          _SearchError(
            message: _errorMessage!,
            onRetry: () => _fetchListings(triggerSearchFlag: true),
          ),
        ],
      );
    }

    if (_results.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24),
        children: [
          _SearchEmpty(
            hasSearched: _hasSearched,
            onRefresh: () => _fetchListings(triggerSearchFlag: true),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final listing = _results[index];
        return ListingCard(
          listing: listing,
          onTap: () {
            _analytics.logEvent(
              'listing_opened_from_search',
              properties: {
                'listing_id': listing.id,
                'position': index,
                'query': _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
              },
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListingDetailScreen(listing: listing),
              ),
            );
          },
        );
      },
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Sort By', style: Theme.of(context).textTheme.titleLarge),
            trailing: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          _SortTile(
            title: 'Recent',
            icon: Icons.access_time,
            selected: _sortOption == _SortOption.recent,
            onTap: () => _updateSort(_SortOption.recent),
          ),
          _SortTile(
            title: 'Value (Low to High)',
            icon: Icons.arrow_upward,
            selected: _sortOption == _SortOption.valueLowToHigh,
            onTap: () => _updateSort(_SortOption.valueLowToHigh),
          ),
          _SortTile(
            title: 'Value (High to Low)',
            icon: Icons.arrow_downward,
            selected: _sortOption == _SortOption.valueHighToLow,
            onTap: () => _updateSort(_SortOption.valueHighToLow),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SortTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: selected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}

class _SearchError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SearchError({
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
            'We couldn\'t complete your search',
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
            ),
            icon: Icon(Icons.refresh),
            label: Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  final bool hasSearched;
  final Future<void> Function() onRefresh;

  const _SearchEmpty({
    required this.hasSearched,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          hasSearched ? Icons.search_off : Icons.search,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        SizedBox(height: 16),
        Text(
          hasSearched ? 'No listings match your filters' : 'Start exploring listings',
          style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          hasSearched
              ? 'Adjust your search or filters to see more results.'
              : 'Use the search bar above or apply filters to discover swap opportunities.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRefresh,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.primary),
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
