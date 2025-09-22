import 'package:flutter/material.dart';
import 'package:swapwing/services/sample_data.dart';
import 'package:swapwing/services/auth_service.dart';
import 'package:swapwing/widgets/listing_card.dart';
import 'package:swapwing/widgets/category_grid.dart';
import 'package:swapwing/widgets/ai_suggestions_card.dart';
import 'package:swapwing/screens/listings/listing_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App bar
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
                icon: Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notifications feature coming soon!')),
                  );
                },
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  
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
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search for items or services...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              border: InputBorder.none,
                            ),
                            onTap: () {
                              // Navigate to search screen
                              DefaultTabController.of(context)?.animateTo(1);
                            },
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
                  
                  // AI Suggestions
                  AISuggestionsCard(),
                  
                  SizedBox(height: 32),
                  
                  // Categories
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
                  
                  // Featured Items
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
                        onPressed: () {
                          // Navigate to search/browse all
                          DefaultTabController.of(context)?.animateTo(1);
                        },
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
          
          // Featured items list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= SampleData.sampleListings.length) return null;
                final listing = SampleData.sampleListings[index];
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListingCard(
                    listing: listing,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingDetailScreen(listing: listing),
                      ),
                    ),
                  ),
                );
              },
              childCount: SampleData.sampleListings.length,
            ),
          ),
          
          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}