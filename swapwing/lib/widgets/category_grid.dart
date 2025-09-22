import 'package:flutter/material.dart';
import 'package:swapwing/services/sample_data.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  final List<CategoryItem> _categories = const [
    CategoryItem(
      title: 'Electronics',
      icon: Icons.devices,
      color: Color(0xFF2D7D73),
    ),
    CategoryItem(
      title: 'Fashion',
      icon: Icons.checkroom,
      color: Color(0xFFFF7043),
    ),
    CategoryItem(
      title: 'Home & Garden',
      icon: Icons.home,
      color: Color(0xFF8E6A47),
    ),
    CategoryItem(
      title: 'Sports',
      icon: Icons.sports_basketball,
      color: Color(0xFF4CAF50),
    ),
    CategoryItem(
      title: 'Books & Media',
      icon: Icons.library_books,
      color: Color(0xFF9C27B0),
    ),
    CategoryItem(
      title: 'Services',
      icon: Icons.handyman,
      color: Color(0xFFFF9800),
    ),
    CategoryItem(
      title: 'Automotive',
      icon: Icons.directions_car,
      color: Color(0xFFE91E63),
    ),
    CategoryItem(
      title: 'Digital',
      icon: Icons.smartphone,
      color: Color(0xFF607D8B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Browsing ${category.title} category...')),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: category.color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  size: 28,
                  color: category.color,
                ),
                SizedBox(height: 8),
                Text(
                  category.title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CategoryItem {
  final String title;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.title,
    required this.icon,
    required this.color,
  });
}