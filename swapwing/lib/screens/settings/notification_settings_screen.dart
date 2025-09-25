import 'package:flutter/material.dart';
import 'package:swapwing/models/notification_preferences.dart';
import 'package:swapwing/services/push_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late NotificationPreferences _preferences;
  late NotificationPermissionStatus _permissionStatus;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _preferences = PushNotificationService.preferencesNotifier.value;
    _permissionStatus =
        PushNotificationService.permissionStatusNotifier.value;
    PushNotificationService.preferencesNotifier.addListener(_onPreferences);
    PushNotificationService.permissionStatusNotifier
        .addListener(_onPermission);
  }

  void _onPreferences() {
    setState(() {
      _preferences = PushNotificationService.preferencesNotifier.value;
    });
  }

  void _onPermission() {
    setState(() {
      _permissionStatus =
          PushNotificationService.permissionStatusNotifier.value;
    });
  }

  @override
  void dispose() {
    PushNotificationService.preferencesNotifier.removeListener(_onPreferences);
    PushNotificationService.permissionStatusNotifier
        .removeListener(_onPermission);
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isRequestingPermission = true;
    });
    final status = await PushNotificationService.requestPermission();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == NotificationPermissionStatus.granted
              ? 'Push notifications are enabled.'
              : 'We could not enable notifications. You can change this in system settings.',
        ),
      ),
    );
    setState(() {
      _isRequestingPermission = false;
    });
  }

  void _updatePreference(bool value, NotificationPreferences Function() apply) {
    final updated = apply();
    PushNotificationService.updatePreferences(updated);
  }

  @override
  Widget build(BuildContext context) {
    final permissionGranted = _permissionStatus ==
            NotificationPermissionStatus.granted ||
        _permissionStatus == NotificationPermissionStatus.provisional;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        permissionGranted
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: permissionGranted
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Push notifications ${_permissionStatus.readableLabel.toLowerCase()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              permissionGranted
                                  ? 'You will receive timely updates about your trades, journeys, and challenges.'
                                  : 'Stay in the loop with trade requests, challenge updates, and community highlights.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isRequestingPermission
                        ? null
                        : permissionGranted
                            ? null
                            : _requestPermission,
                    icon: _isRequestingPermission
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications_active_outlined),
                    label: Text(permissionGranted
                        ? 'Enabled'
                        : 'Enable push notifications'),
                  ),
                  if (!permissionGranted) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Already denied? Open your system settings to allow SwapWing notifications.',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Theme.of(context).hintColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Customize alerts',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _PreferenceTile(
            enabled: permissionGranted,
            title: 'Trade activity',
            subtitle:
                'Requests, offers, and updates for your listings and swaps.',
            value: _preferences.tradeActivity,
            onChanged: (value) => _updatePreference(
              value,
              () => _preferences.copyWith(tradeActivity: value),
            ),
          ),
          _PreferenceTile(
            enabled: permissionGranted,
            title: 'Journey updates',
            subtitle: 'Alerts when followers interact or new steps publish.',
            value: _preferences.journeyUpdates,
            onChanged: (value) => _updatePreference(
              value,
              () => _preferences.copyWith(journeyUpdates: value),
            ),
          ),
          _PreferenceTile(
            enabled: permissionGranted,
            title: 'Challenge highlights',
            subtitle: 'Rank changes and reminders to log challenge progress.',
            value: _preferences.challengeHighlights,
            onChanged: (value) => _updatePreference(
              value,
              () => _preferences.copyWith(challengeHighlights: value),
            ),
          ),
          _PreferenceTile(
            enabled: permissionGranted,
            title: 'Community spotlights',
            subtitle: 'Stories from traders you follow and featured journeys.',
            value: _preferences.communitySpotlights,
            onChanged: (value) => _updatePreference(
              value,
              () => _preferences.copyWith(communitySpotlights: value),
            ),
          ),
          _PreferenceTile(
            enabled: true,
            title: 'Product announcements',
            subtitle:
                'Occasional updates about new SwapWing features and tips.',
            value: _preferences.productAnnouncements,
            onChanged: (value) => _updatePreference(
              value,
              () => _preferences.copyWith(productAnnouncements: value),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why enable notifications?',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Push alerts make it easier to respond to trade requests, celebrate challenge milestones, and stay current with your SwapWing circle without constantly checking the app.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const _PreferenceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}
