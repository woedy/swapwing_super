import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swapwing/models/challenge.dart';
import 'package:swapwing/services/analytics_service.dart';
import 'package:swapwing/services/challenge_service.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ChallengeService _challengeService;
  final AnalyticsService _analytics = AnalyticsService.instance;
  StreamSubscription<Challenge>? _challengeSubscription;
  StreamSubscription<List<ChallengeProgressUpdate>>? _updatesSubscription;
  late Challenge _challenge;
  List<ChallengeProgressUpdate> _updates = [];
  bool _isActionInFlight = false;
  bool _isLoggingProgress = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _challengeService = ChallengeService();
    _challenge = widget.challenge;
    _challengeService.ensureChallengeCached(_challenge);
    _challengeSubscription =
        _challengeService.watchChallenge(_challenge.id).listen((value) {
      if (!mounted) return;
      setState(() {
        _challenge = value;
      });
    });
    _updatesSubscription =
        _challengeService.watchProgressFeed(_challenge.id).listen((value) {
      if (!mounted) return;
      setState(() {
        _updates = value;
      });
    });
    _analytics.logEvent(
      'challenge_detail_viewed',
      properties: {
        'challenge_id': _challenge.id,
        'status': _challenge.status.name,
        'has_joined': _challenge.hasJoined,
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _challengeSubscription?.cancel();
    _updatesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleJoinOrLeave() async {
    if (_isActionInFlight) return;
    setState(() {
      _isActionInFlight = true;
    });

    try {
      if (_challenge.hasJoined) {
        _analytics.logEvent(
          'challenge_leave_attempted',
          properties: {'challenge_id': _challenge.id},
        );
        await _challengeService.leaveChallenge(_challenge.id);
        _showSnack('Left the challenge');
        _analytics.logEvent(
          'challenge_left',
          properties: {'challenge_id': _challenge.id},
        );
      } else {
        _analytics.logEvent(
          'challenge_join_attempted',
          properties: {'challenge_id': _challenge.id},
        );
        await _challengeService.joinChallenge(_challenge.id);
        _showSnack('Joined challenge!');
        _analytics.logEvent(
          'challenge_joined',
          properties: {'challenge_id': _challenge.id},
        );
      }
    } on ChallengeServiceException catch (error) {
      _analytics.logEvent(
        'challenge_action_failed',
        properties: {
          'challenge_id': _challenge.id,
          'reason': error.message,
        },
      );
      _showError(error.message);
    } catch (_) {
      _analytics.logEvent(
        'challenge_action_failed',
        properties: {
          'challenge_id': _challenge.id,
          'reason': 'unexpected_error',
        },
      );
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isActionInFlight = false;
        });
      }
    }
  }

  Future<void> _logProgress() async {
    final progress = _challenge.currentUserProgress;
    if (progress == null) {
      _showError('Join the challenge to log your trades.');
      return;
    }
    if (_challenge.status != ChallengeStatus.active) {
      _showError('This challenge is not active right now.');
      return;
    }
    if (_isLoggingProgress) return;

    _analytics.logEvent(
      'challenge_progress_sheet_opened',
      properties: {'challenge_id': _challenge.id},
    );

    final result = await showModalBottomSheet<_LogProgressResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LogProgressSheet(currentValue: progress.currentValue),
    );

    if (result == null) {
      _analytics.logEvent(
        'challenge_progress_cancelled',
        properties: {'challenge_id': _challenge.id},
      );
      return;
    }

    setState(() {
      _isLoggingProgress = true;
    });

    _analytics.logEvent(
      'challenge_progress_submitted',
      properties: {
        'challenge_id': _challenge.id,
        'new_value': result.newValue,
      },
    );

    try {
      await _challengeService.submitProgressUpdate(
        _challenge.id,
        newValue: result.newValue,
        note: result.note,
      );
      _showSnack('Progress saved!');
      _analytics.logEvent(
        'challenge_progress_saved',
        properties: {
          'challenge_id': _challenge.id,
          'new_value': result.newValue,
        },
      );
    } on ChallengeServiceException catch (error) {
      _analytics.logEvent(
        'challenge_progress_failed',
        properties: {
          'challenge_id': _challenge.id,
          'reason': error.message,
        },
      );
      _showError(error.message);
    } catch (_) {
      _analytics.logEvent(
        'challenge_progress_failed',
        properties: {
          'challenge_id': _challenge.id,
          'reason': 'unexpected_error',
        },
      );
      _showError('Unable to save your progress right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingProgress = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _challenge.bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_challenge.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(_challenge.status),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _challenge.title,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.share, color: Colors.white),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Challenge stats
                Container(
                  margin: EdgeInsets.all(16),
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
                        child: _buildStatItem(
                          '${_challenge.participantCount}',
                          'Participants',
                          Icons.people,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Theme.of(context).dividerColor,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          '\$${_challenge.targetValue.toStringAsFixed(0)}',
                          'Goal Value',
                          Icons.flag,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Theme.of(context).dividerColor,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          _challenge.timeRemaining,
                          'Time Left',
                          Icons.timer,
                        ),
                      ),
                    ],
                  ),
                ),

                // Description and details
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About this Challenge',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        _challenge.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Item',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  _challenge.startItem,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Goal Item',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  _challenge.goalItem,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                if (_challenge.currentUserProgress != null)
                  _buildUserProgressCard(),

                SizedBox(height: 16),

                // Tab bar for updates, rules, and leaderboard
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
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
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        tabs: [
                          Tab(text: 'Updates'),
                          Tab(text: 'Rules'),
                          Tab(text: 'Leaderboard'),
                        ],
                      ),
                      Container(
                        height: 360,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildUpdatesTab(),
                            _buildRulesTab(),
                            _buildLeaderboardTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 100), // Space for floating button
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildJoinButton(),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProgressCard() {
    final progress = _challenge.currentUserProgress;
    if (progress == null) {
      return SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildUserProgressStat(
                  _formatCurrency(progress.currentValue),
                  'Current Value',
                ),
              ),
              Expanded(
                child: _buildUserProgressStat(
                  '${progress.tradesCompleted}',
                  'Trades Logged',
                ),
              ),
              Expanded(
                child: _buildUserProgressStat(
                  progress.rank > 0 ? '#${progress.rank}' : '—',
                  'Leaderboard Rank',
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _challenge.status == ChallengeStatus.active && !_isLoggingProgress
                  ? _logProgress
                  : null,
              icon: _isLoggingProgress
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Icon(Icons.add_task),
              label: Text(_isLoggingProgress ? 'Saving...' : 'Log Trade Progress'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Last trade ${_formatRelativeTime(progress.lastTradeAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProgressStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildUpdatesTab() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Progress Feed',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: _updates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No updates yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                        Text(
                          'Be the first to record a trade or check back soon.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _updates.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final update = _updates[index];
                      return _buildUpdateCard(update);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(ChallengeProgressUpdate update) {
    final theme = Theme.of(context);
    final isCurrentUser =
        _challenge.currentUserProgress?.userId == update.userId;
    final message = update.message.isNotEmpty
        ? update.message
        : '${update.userName} logged new progress.';
    final delta = update.valueDelta;
    final isGain = delta >= 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? theme.colorScheme.primary.withOpacity(0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? theme.colorScheme.primary.withOpacity(0.4)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                backgroundImage: update.avatarUrl.isNotEmpty
                    ? NetworkImage(update.avatarUrl)
                    : null,
                child: update.avatarUrl.isEmpty
                    ? Text(
                        update.userName.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            update.userName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _formatRelativeTime(update.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'You',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildValueChip(
                'Total ${_formatCurrency(update.newValue)}',
                theme.colorScheme.primary,
              ),
              if (delta.abs() > 0.01)
                _buildValueChip(
                  '${isGain ? '+' : '-'}${_formatCurrency(delta.abs())}',
                  isGain ? Colors.green : Colors.redAccent,
                ),
              _buildValueChip(
                '${update.tradesCompleted} trades overall',
                theme.colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildRulesTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge Rules',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _challenge.rules.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 4, right: 8),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _challenge.rules[index],
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Participants',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          if (_challenge.topParticipants.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.leaderboard,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No participants yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      'Be the first to join!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _challenge.topParticipants.length,
                itemBuilder: (context, index) {
                  final participant = _challenge.topParticipants[index];
                  final isCurrentUser =
                      _challenge.currentUserProgress?.userId ==
                          participant.userId;
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                          : (index < 3
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : Theme.of(context).colorScheme.surface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentUser
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.4)
                            : (index < 3
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3)
                                : Colors.transparent),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getRankColor(participant.rank),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '#${participant.rank}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          backgroundImage: participant.avatarUrl.isNotEmpty
                              ? NetworkImage(participant.avatarUrl)
                              : null,
                          child: participant.avatarUrl.isEmpty
                              ? Text(
                                  participant.userName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
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
                                participant.userName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isCurrentUser)
                                Text(
                                  'You',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              Text(
                                '${participant.tradesCompleted} trades',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(participant.currentValue),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    if (_challenge.status == ChallengeStatus.ended) {
      return FloatingActionButton.extended(
        onPressed: null,
        label: Text('Challenge Ended'),
        icon: Icon(Icons.flag),
        backgroundColor: Colors.grey,
      );
    }

    final isActive = _challenge.status == ChallengeStatus.active;
    final isJoined = _challenge.hasJoined;

    return FloatingActionButton.extended(
      onPressed: isActive ? _handleJoinOrLeave : null,
      label: Text(
        _isActionInFlight
            ? (isJoined ? 'Leaving...' : 'Joining...')
            : (isJoined ? 'Leave Challenge' : 'Join Challenge'),
      ),
      icon: _isActionInFlight
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(isJoined ? Icons.exit_to_app : Icons.play_arrow),
      backgroundColor: isJoined
          ? Colors.redAccent
          : Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );
  }

  String _formatCurrency(double value) {
    final hasCents = value % 1 != 0;
    final formatted = hasCents
        ? value.toStringAsFixed(2)
        : value.toStringAsFixed(0);
    return '${String.fromCharCode(36)}$formatted';
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    final weeks = (difference.inDays / 7).floor();
    if (weeks < 4) {
      return '${weeks}w ago';
    }
    final months = (difference.inDays / 30).floor();
    if (months < 12) {
      return '${months}mo ago';
    }
    final years = (difference.inDays / 365).floor();
    return '${years}y ago';
  }

  Color _getStatusColor(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.active:
        return Colors.green;
      case ChallengeStatus.upcoming:
        return Colors.orange;
      case ChallengeStatus.ended:
        return Colors.grey;
    }
  }

  String _getStatusText(ChallengeStatus status) {
    switch (status) {
      case ChallengeStatus.active:
        return 'LIVE';
      case ChallengeStatus.upcoming:
        return 'COMING SOON';
      case ChallengeStatus.ended:
        return 'ENDED';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[600]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class _LogProgressResult {
  final double newValue;
  final String note;

  const _LogProgressResult({
    required this.newValue,
    required this.note,
  });
}

class _LogProgressSheet extends StatefulWidget {
  final double currentValue;

  const _LogProgressSheet({super.key, required this.currentValue});

  @override
  State<_LogProgressSheet> createState() => _LogProgressSheetState();
}

class _LogProgressSheetState extends State<_LogProgressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final suggested = widget.currentValue + 100;
    _valueController = TextEditingController(
      text: suggested.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final parsed = double.tryParse(_valueController.text.trim()) ??
        widget.currentValue;
    Navigator.of(context).pop(
      _LogProgressResult(
        newValue: parsed,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Log Trade Progress',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Current total: ${String.fromCharCode(36)}${widget.currentValue.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                decoration: InputDecoration(
                  labelText: 'New total value',
                  prefixText: '${String.fromCharCode(36)}',
                ),
                validator: (value) {
                  final trimmed = value?.trim();
                  if (trimmed == null || trimmed.isEmpty) {
                    return 'Enter the total value after your latest trade.';
                  }
                  final parsed = double.tryParse(trimmed);
                  if (parsed == null) {
                    return 'Please enter a valid number.';
                  }
                  if (parsed <= widget.currentValue) {
                    return 'New total must be greater than your current value.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'What did you trade?',
                  hintText: 'Share quick details so followers can celebrate with you.',
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text('Save Progress'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}