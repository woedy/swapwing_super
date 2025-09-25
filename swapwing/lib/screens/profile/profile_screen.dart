import 'package:flutter/material.dart';
import 'package:swapwing/services/auth_service.dart';
import 'package:swapwing/services/sample_data.dart';
import 'package:swapwing/screens/auth/welcome_screen.dart';
import 'package:swapwing/screens/settings/feedback_screen.dart';
import 'package:swapwing/screens/settings/notification_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser ?? SampleData.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => _showSettingsBottomSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Container(
              padding: EdgeInsets.all(24),
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
                children: [
                  // Profile image
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.profileImageUrl != null 
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: user.profileImageUrl == null 
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Username and verification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.username,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (user.isVerified) ...[
                        SizedBox(width: 8),
                        Icon(
                          Icons.verified,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ],
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  if (user.bio != null)
                    Text(
                      user.bio!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  
                  SizedBox(height: 20),
                  
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProfileStat(
                        icon: Icons.swap_horiz,
                        label: 'Trades',
                        value: '${user.totalTrades}',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      _ProfileStat(
                        icon: Icons.star,
                        label: 'Trust Score',
                        value: '${user.trustScore}',
                        color: Colors.amber,
                      ),
                      _ProfileStat(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: user.location?.split(',').first ?? 'Unknown',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Quick actions
            _ProfileSection(
              title: 'Quick Actions',
              children: [
                _ProfileMenuItem(
                  icon: Icons.inventory_2,
                  title: 'My Listings',
                  subtitle: 'Manage your active listings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('My listings feature coming soon!')),
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.history,
                  title: 'Trade History',
                  subtitle: 'View your past trades',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Trade history feature coming soon!')),
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.favorite,
                  title: 'Saved Items',
                  subtitle: 'Items you\'ve bookmarked',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved items feature coming soon!')),
                    );
                  },
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Account section
            _ProfileSection(
              title: 'Account',
              children: [
                _ProfileMenuItem(
                  icon: Icons.edit,
                  title: 'Edit Profile',
                  subtitle: 'Update your information',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Edit profile feature coming soon!')),
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage push and email alerts',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.privacy_tip,
                  title: 'Privacy & Safety',
                  subtitle: 'Control your privacy settings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Privacy settings coming soon!')),
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.feedback_outlined,
                  title: 'Feedback & Support',
                  subtitle: 'Share ideas or report an issue',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FeedbackScreen(),
                      ),
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  textColor: Theme.of(context).colorScheme.error,
                  onTap: () => _showSignOutDialog(context),
                ),
              ],
            ),
            
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
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
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 24),
            
            ListTile(
              leading: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
              title: Text('Dark Mode'),
              trailing: Switch(
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Theme switching coming soon!')),
                  );
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            ListTile(
              leading: Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
              title: Text('Language'),
              subtitle: Text('English'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language settings coming soon!')),
                );
              },
            ),

            ListTile(
              leading: Icon(Icons.feedback, color: Theme.of(context).colorScheme.primary),
              title: Text('Send Feedback'),
              subtitle: Text('Share ideas or report an issue'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
                );
              },
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.children,
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? textColor;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? Theme.of(context).colorScheme.onSurface;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: color.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}