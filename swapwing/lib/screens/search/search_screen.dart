import 'package:flutter/material.dart';
import 'package:swapwing/services/sample_data.dart';
import 'package:swapwing/widgets/listing_card.dart';
import 'package:swapwing/screens/listings/listing_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showFilters = false;
  String _selectedCategory = 'All';
  double _maxDistance = 50.0;
  RangeValues _priceRange = RangeValues(0, 1000);

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search header
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
                  // Search bar
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
                            onChanged: (value) {
                              // Implement search functionality
                            },
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
                  
                  // Filter and sort options
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
                          onPressed: () {
                            _showSortBottomSheet(context);
                          },
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
            
            // Filter panel
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: _showFilters ? 200 : 0,
              child: _showFilters ? _buildFilterPanel() : null,
            ),
            
            // Search results
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: SampleData.sampleListings.length,
                itemBuilder: (context, index) {
                  final listing = SampleData.sampleListings[index];
                  return ListingCard(
                    listing: listing,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingDetailScreen(listing: listing),
                      ),
                    ),
                  );
                },
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
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          SizedBox(height: 16),
          
          // Category filter
          Text(
            'Category',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['All', ...SampleData.categories.take(4)].map((category) {
              final isSelected = _selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedCategory = category);
                },
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
          
          SizedBox(height: 16),
          
          // Distance slider
          Text(
            'Distance: ${_maxDistance.round()} km',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              setState(() => _maxDistance = value);
            },
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 24),
            
            _SortOption(title: 'Recent', icon: Icons.access_time),
            _SortOption(title: 'Distance', icon: Icons.location_on),
            _SortOption(title: 'Value (Low to High)', icon: Icons.arrow_upward),
            _SortOption(title: 'Value (High to Low)', icon: Icons.arrow_downward),
            _SortOption(title: 'Most Popular', icon: Icons.trending_up),
            
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SortOption({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sorting by $title...')),
        );
      },
    );
  }
}