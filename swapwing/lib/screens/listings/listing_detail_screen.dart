import 'dart:io';

import 'package:flutter/material.dart';
import 'package:swapwing/models/listing.dart';
import 'package:swapwing/services/analytics_service.dart';

class ListingDetailScreen extends StatefulWidget {
  final SwapListing listing;

  const ListingDetailScreen({
    super.key,
    required this.listing,
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  int _currentImageIndex = 0;
  late final AnalyticsService _analytics;

  @override
  void initState() {
    super.initState();
    _analytics = AnalyticsService.instance;
    _analytics.logEvent(
      'listing_detail_viewed',
      properties: {
        'listing_id': widget.listing.id,
        'category': widget.listing.category.name,
        'owner_id': widget.listing.owner?.id,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.listing.imageUrls;
    final owner = widget.listing.owner;
    final ownerName = owner?.displayName ?? 'SwapWing Trader';
    final ownerInitials = owner?.initials ?? 'S';
    final ownerEmail = owner?.email;
    final ownerAvatar = owner?.avatarUrl;
    final estimatedValue = widget.listing.estimatedValue;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    _analytics.logEvent(
                      'listing_share_tapped',
                      properties: {'listing_id': widget.listing.id},
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Share feature coming soon!')),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: images.isNotEmpty
                  ? PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemBuilder: (context, index) {
                        return _buildListingImage(context, images[index]);
                      },
                    )
                  : _buildImageFallback(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (images.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: entry.key == _currentImageIndex
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.listing.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                      if (widget.listing.isTradeUpEligible)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Trade-Up',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (estimatedValue != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Estimated Value: \$${estimatedValue.toInt()}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  if (widget.listing.location != null) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.listing.location!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 20),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.listing.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          height: 1.5,
                        ),
                  ),
                  SizedBox(height: 20),
                  if (widget.listing.tags.isNotEmpty) ...[
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.listing.tags
                          .map(
                            (tag) => Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '#$tag',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: 20),
                  ],
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: ownerAvatar != null ? NetworkImage(ownerAvatar) : null,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: ownerAvatar == null
                              ? Text(
                                  ownerInitials,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                )
                              : null,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ownerName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                              if (ownerEmail != null && ownerEmail.isNotEmpty)
                                Text(
                                  ownerEmail,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                )
                              else
                                Text(
                                  'Trusted SwapWing trader',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Profile feature coming soon!')),
                            );
                          },
                          child: Text(
                            'View Profile',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'AI Suggestions',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Items that would make great trades for this listing:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Photography equipment\n• Design software\n• Art supplies',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Chat feature coming soon!')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.primary),
                  label: Text(
                    'Message',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Offer flow coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: Icon(Icons.swap_horiz),
                  label: Text(
                    'Make an Offer',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Icon(
        Icons.image,
        size: 64,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }

  Widget _buildListingImage(BuildContext context, String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageFallback(context),
      );
    }

    if (uri != null && uri.scheme == 'file') {
      final file = File(uri.toFilePath());
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildImageFallback(context),
        );
      }
    }

    final file = File(imageUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageFallback(context),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImageFallback(context),
    );
  }
}
