import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:swapwing/config/environment.dart';
import 'package:swapwing/models/challenge.dart';
import 'package:swapwing/services/auth_service.dart';
import 'package:swapwing/services/sample_data.dart';

class ChallengeServiceException implements Exception {
  final String message;

  const ChallengeServiceException(this.message);

  @override
  String toString() => 'ChallengeServiceException: $message';
}

class ChallengeService {
  ChallengeService._internal() {
    _challengeListController.onListen = () {
      _challengeListController.add(_sortedChallenges());
    };
  }

  static final ChallengeService _instance = ChallengeService._internal();

  factory ChallengeService() => _instance;

  final Map<String, Challenge> _challenges = {};
  final Map<String, List<ChallengeProgressUpdate>> _challengeUpdates = {};
  final Map<String, StreamController<Challenge>> _challengeControllers = {};
  final Map<String, StreamController<List<ChallengeProgressUpdate>>>
      _updateControllers = {};
  final StreamController<List<Challenge>> _challengeListController =
      StreamController<List<Challenge>>.broadcast();
  final Map<String, Timer> _mockTimers = {};
  final Random _random = Random();

  Future<List<Challenge>> fetchChallenges({
    bool refresh = false,
    http.Client? client,
  }) async {
    if (EnvironmentConfig.useMockData) {
      _seedMockData(force: refresh);
      final list = _sortedChallenges();
      _emitChallengeList(list);
      return list;
    }

    final token = await AuthService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw const ChallengeServiceException(
        'Sign in to browse SwapWing challenges.',
      );
    }

    final baseUrl = EnvironmentConfig.apiBaseUrl;
    final normalizedBase =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse('$normalizedBase/api/challenges/');

    final httpClient = client ?? http.Client();
    late http.Response response;
    try {
      response = await httpClient.get(
        uri,
        headers: {
          'Authorization': 'Token $token',
          'Accept': 'application/json',
        },
      );
    } catch (_) {
      throw const ChallengeServiceException(
        'Unable to reach the SwapWing challenge service. Please try again shortly.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    if (response.statusCode != 200) {
      throw ChallengeServiceException(
        'Loading challenges failed with status ${response.statusCode}.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      final rawChallenges = _extractResults(decoded);
      final challenges = rawChallenges
          .map((item) => Challenge.fromApi(item))
          .toList(growable: false);

      _challenges
        ..clear()
        ..addEntries(
          challenges.map((challenge) => MapEntry(challenge.id, challenge)),
        );
      final list = _sortedChallenges();
      _emitChallengeList(list);
      return list;
    } catch (_) {
      throw const ChallengeServiceException(
        'We hit a snag decoding challenges from the server response.',
      );
    }
  }

  void ensureChallengeCached(Challenge challenge) {
    if (!_challenges.containsKey(challenge.id)) {
      _challenges[challenge.id] = challenge;
      _challengeUpdates.putIfAbsent(challenge.id, () => <ChallengeProgressUpdate>[]);
      _emitChallengeList();
    }
  }

  Stream<List<Challenge>> watchChallenges() {
    Future.microtask(() {
      if (_challengeListController.hasListener) {
        _challengeListController.add(_sortedChallenges());
      }
    });
    return _challengeListController.stream;
  }

  Stream<Challenge> watchChallenge(String challengeId) {
    final controller = _challengeControllers.putIfAbsent(
      challengeId,
      () {
        late final StreamController<Challenge> newController;
        newController = StreamController<Challenge>.broadcast(
          onListen: () {
            final challenge = _challenges[challengeId];
            if (challenge != null) {
              newController.add(challenge);
            }
            _maybeStartMockTimer(challengeId);
          },
          onCancel: () {
            if (!_hasActiveListeners(challengeId)) {
              _stopMockTimer(challengeId);
            }
          },
        );
        return newController;
      },
    );

    Future.microtask(() {
      final challenge = _challenges[challengeId];
      if (challenge != null) {
        controller.add(challenge);
      }
    });

    return controller.stream;
  }

  Stream<List<ChallengeProgressUpdate>> watchProgressFeed(String challengeId) {
    final controller = _updateControllers.putIfAbsent(
      challengeId,
      () {
        late final StreamController<List<ChallengeProgressUpdate>> newController;
        newController = StreamController<List<ChallengeProgressUpdate>>.broadcast(
          onListen: () {
            final updates = _challengeUpdates[challengeId] ?? const [];
            newController.add(List.unmodifiable(updates));
            _maybeStartMockTimer(challengeId);
          },
          onCancel: () {
            if (!_hasActiveListeners(challengeId)) {
              _stopMockTimer(challengeId);
            }
          },
        );
        return newController;
      },
    );

    Future.microtask(() {
      final updates = _challengeUpdates[challengeId] ?? const [];
      controller.add(List.unmodifiable(updates));
    });

    return controller.stream;
  }

  Future<Challenge> joinChallenge(String challengeId) async {
    final challenge = _challenges[challengeId];
    if (challenge == null) {
      throw const ChallengeServiceException('Challenge not found.');
    }
    if (challenge.status != ChallengeStatus.active) {
      throw const ChallengeServiceException(
        'This challenge is not currently accepting new participants.',
      );
    }
    if (challenge.hasJoined) {
      return challenge;
    }

    await _simulateNetworkLatency();

    final user = AuthService.currentUser ?? SampleData.currentUser;
    final avatarUrl = user.profileImageUrl ??
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face';
    final now = DateTime.now();
    final participant = ChallengeParticipant(
      userId: user.id,
      userName: user.username,
      avatarUrl: avatarUrl,
      currentValue: challenge.currentUserProgress?.currentValue ?? 0.0,
      rank: challenge.currentUserProgress?.rank ?? challenge.topParticipants.length + 1,
      journeyId: 'journey_${challengeId}_${user.id}',
      tradesCompleted: challenge.currentUserProgress?.tradesCompleted ?? 0,
      joinedAt: challenge.currentUserProgress?.joinedAt ?? now,
      lastTradeAt: challenge.currentUserProgress?.lastTradeAt ?? now,
    );

    final updatedChallenge = challenge.copyWith(
      hasJoined: true,
      participantCount: challenge.participantCount + 1,
      currentUserProgress: participant,
      topParticipants: _recalculateTopParticipants(
        challenge.topParticipants,
        currentUser: participant,
      ),
    );

    _challenges[challengeId] = updatedChallenge;
    _emitChallenge(updatedChallenge);

    _addProgressUpdate(
      challengeId,
      ChallengeProgressUpdate(
        id: 'update_${DateTime.now().millisecondsSinceEpoch}',
        challengeId: challengeId,
        userId: participant.userId,
        userName: participant.userName,
        avatarUrl: participant.avatarUrl,
        previousValue: participant.currentValue,
        newValue: participant.currentValue,
        tradesCompleted: participant.tradesCompleted,
        message: '${participant.userName} joined the challenge!',
        timestamp: now,
      ),
    );

    return updatedChallenge;
  }

  Future<Challenge> leaveChallenge(String challengeId) async {
    final challenge = _challenges[challengeId];
    if (challenge == null) {
      throw const ChallengeServiceException('Challenge not found.');
    }
    if (!challenge.hasJoined) {
      return challenge;
    }

    await _simulateNetworkLatency();

    final user = AuthService.currentUser ?? SampleData.currentUser;
    final filteredTop = challenge.topParticipants
        .where((participant) => participant.userId != user.id)
        .toList();
    final updatedChallenge = challenge.copyWith(
      hasJoined: false,
      participantCount: max(challenge.participantCount - 1, 0),
      currentUserProgress: null,
      topParticipants: _recalculateTopParticipants(filteredTop),
    );

    _challenges[challengeId] = updatedChallenge;
    _emitChallenge(updatedChallenge);

    _addProgressUpdate(
      challengeId,
      ChallengeProgressUpdate(
        id: 'update_${DateTime.now().millisecondsSinceEpoch}',
        challengeId: challengeId,
        userId: user.id,
        userName: user.username,
        avatarUrl: user.profileImageUrl ??
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        previousValue: challenge.currentUserProgress?.currentValue ?? 0.0,
        newValue: challenge.currentUserProgress?.currentValue ?? 0.0,
        tradesCompleted: challenge.currentUserProgress?.tradesCompleted ?? 0,
        message: '${user.username} left the challenge.',
        timestamp: DateTime.now(),
      ),
    );

    return updatedChallenge;
  }

  Future<ChallengeProgressUpdate> submitProgressUpdate(
    String challengeId, {
    required double newValue,
    required String note,
  }) async {
    final challenge = _challenges[challengeId];
    if (challenge == null) {
      throw const ChallengeServiceException('Challenge not found.');
    }
    final participant = challenge.currentUserProgress;
    if (participant == null || !challenge.hasJoined) {
      throw const ChallengeServiceException(
        'Join the challenge before logging progress.',
      );
    }
    if (challenge.status != ChallengeStatus.active) {
      throw const ChallengeServiceException(
        'This challenge is not active right now.',
      );
    }
    if (newValue <= participant.currentValue) {
      throw const ChallengeServiceException(
        'Your trade needs to increase your total value. Try a higher amount.',
      );
    }

    await _simulateNetworkLatency();

    final updatedParticipant = participant.copyWith(
      currentValue: newValue,
      tradesCompleted: participant.tradesCompleted + 1,
      lastTradeAt: DateTime.now(),
    );

    final updatedChallenge = challenge.copyWith(
      currentUserProgress: updatedParticipant,
      topParticipants: _recalculateTopParticipants(
        challenge.topParticipants,
        currentUser: updatedParticipant,
      ),
    );

    _challenges[challengeId] = updatedChallenge;
    _emitChallenge(updatedChallenge);

    final update = ChallengeProgressUpdate(
      id: 'update_${DateTime.now().millisecondsSinceEpoch}',
      challengeId: challengeId,
      userId: updatedParticipant.userId,
      userName: updatedParticipant.userName,
      avatarUrl: updatedParticipant.avatarUrl,
      previousValue: participant.currentValue,
      newValue: updatedParticipant.currentValue,
      tradesCompleted: updatedParticipant.tradesCompleted,
      message: note.isNotEmpty
          ? note
          : 'Logged a new trade worth \$${newValue.toStringAsFixed(0)}.',
      timestamp: DateTime.now(),
    );

    _addProgressUpdate(challengeId, update);
    return update;
  }

  void _simulateCompetitorProgress(String challengeId) {
    if (!EnvironmentConfig.useMockData) {
      return;
    }
    final challenge = _challenges[challengeId];
    if (challenge == null) {
      return;
    }
    if (challenge.topParticipants.isEmpty) {
      return;
    }

    final index = _random.nextInt(challenge.topParticipants.length);
    final current = challenge.topParticipants[index];
    final delta = 50 + _random.nextInt(120) + _random.nextDouble();
    final newValue = current.currentValue + delta;
    final updatedParticipant = current.copyWith(
      currentValue: newValue,
      tradesCompleted: current.tradesCompleted + 1,
      lastTradeAt: DateTime.now(),
    );

    final participants = List<ChallengeParticipant>.from(challenge.topParticipants);
    participants[index] = updatedParticipant;

    final recalculated = _recalculateTopParticipants(
      participants,
      currentUser: challenge.currentUserProgress,
    );

    final updatedChallenge = challenge.copyWith(topParticipants: recalculated);
    _challenges[challengeId] = updatedChallenge;
    _emitChallenge(updatedChallenge);

    _addProgressUpdate(
      challengeId,
      ChallengeProgressUpdate(
        id: 'update_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(999)}',
        challengeId: challengeId,
        userId: updatedParticipant.userId,
        userName: updatedParticipant.userName,
        avatarUrl: updatedParticipant.avatarUrl,
        previousValue: newValue - delta,
        newValue: newValue,
        tradesCompleted: updatedParticipant.tradesCompleted,
        message:
            '${updatedParticipant.userName} completed a swap pushing their total to \$${newValue.toStringAsFixed(0)}.',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _addProgressUpdate(String challengeId, ChallengeProgressUpdate update) {
    final updates = _challengeUpdates.putIfAbsent(
      challengeId,
      () => <ChallengeProgressUpdate>[],
    );
    updates.insert(0, update);
    if (updates.length > 40) {
      updates.removeRange(40, updates.length);
    }

    final controller = _updateControllers[challengeId];
    if (controller != null && controller.hasListener) {
      controller.add(List.unmodifiable(updates));
    }
  }

  void _emitChallenge(Challenge challenge) {
    final controller = _challengeControllers[challenge.id];
    if (controller != null && controller.hasListener) {
      controller.add(challenge);
    }
    _emitChallengeList();
  }

  void _emitChallengeList([List<Challenge>? list]) {
    if (!_challengeListController.hasListener) {
      return;
    }
    _challengeListController.add(list ?? _sortedChallenges());
  }

  void _maybeStartMockTimer(String challengeId) {
    if (!EnvironmentConfig.useMockData) {
      return;
    }
    if (_mockTimers.containsKey(challengeId)) {
      return;
    }
    _mockTimers[challengeId] = Timer.periodic(
      Duration(seconds: 12 + _random.nextInt(6)),
      (_) => _simulateCompetitorProgress(challengeId),
    );
  }

  void _stopMockTimer(String challengeId) {
    _mockTimers.remove(challengeId)?.cancel();
  }

  bool _hasActiveListeners(String challengeId) {
    final challengeController = _challengeControllers[challengeId];
    final updatesController = _updateControllers[challengeId];
    final challengeActive = challengeController?.hasListener ?? false;
    final updatesActive = updatesController?.hasListener ?? false;
    return challengeActive || updatesActive;
  }

  void _seedMockData({bool force = false}) {
    if (_challenges.isNotEmpty && !force) {
      if (_challengeUpdates.isEmpty) {
        final updateSeed = SampleData.getChallengeUpdates();
        updateSeed.forEach((id, updates) {
          _challengeUpdates[id] = List<ChallengeProgressUpdate>.from(updates);
        });
      }
      return;
    }

    _challenges
      ..clear()
      ..addEntries(
        SampleData.getSampleChallenges().map(
          (challenge) => MapEntry(challenge.id, challenge),
        ),
      );

    _challengeUpdates
      ..clear()
      ..addEntries(
        SampleData.getChallengeUpdates().map(
          (id, updates) => MapEntry(
            id,
            List<ChallengeProgressUpdate>.from(updates),
          ),
        ),
      );

    for (final id in _challenges.keys) {
      _challengeUpdates.putIfAbsent(id, () => <ChallengeProgressUpdate>[]);
    }
  }

  List<Challenge> _sortedChallenges() {
    final list = _challenges.values.toList();
    int orderForStatus(ChallengeStatus status) {
      switch (status) {
        case ChallengeStatus.active:
          return 0;
        case ChallengeStatus.upcoming:
          return 1;
        case ChallengeStatus.ended:
          return 2;
      }
    }

    list.sort((a, b) {
      final statusComparison =
          orderForStatus(a.status).compareTo(orderForStatus(b.status));
      if (statusComparison != 0) {
        return statusComparison;
      }
      return a.endDate.compareTo(b.endDate);
    });
    return List<Challenge>.unmodifiable(list);
  }

  List<ChallengeParticipant> _recalculateTopParticipants(
    List<ChallengeParticipant> participants, {
    ChallengeParticipant? currentUser,
  }) {
    final merged = <ChallengeParticipant>[];
    final seen = <String>{};

    for (final participant in participants) {
      if (seen.add(participant.userId)) {
        merged.add(participant);
      }
    }

    if (currentUser != null) {
      if (!seen.contains(currentUser.userId)) {
        merged.add(currentUser);
        seen.add(currentUser.userId);
      } else {
        for (var i = 0; i < merged.length; i++) {
          if (merged[i].userId == currentUser.userId) {
            merged[i] = currentUser;
            break;
          }
        }
      }
    }

    merged.sort((a, b) => b.currentValue.compareTo(a.currentValue));

    final ranked = <ChallengeParticipant>[];
    for (var i = 0; i < merged.length; i++) {
      ranked.add(merged[i].copyWith(rank: i + 1));
    }

    ChallengeParticipant? userEntry;
    if (currentUser != null) {
      try {
        userEntry = ranked.firstWhere(
          (participant) => participant.userId == currentUser.userId,
        );
      } catch (_) {
        userEntry = null;
      }
    }

    final limited = ranked.take(5).toList();
    if (userEntry != null &&
        !limited.any((participant) => participant.userId == userEntry!.userId)) {
      limited.add(userEntry);
    }
    return limited;
  }

  Future<void> _simulateNetworkLatency() async {
    await Future.delayed(Duration(milliseconds: 450 + _random.nextInt(250)));
  }

  List<Map<String, dynamic>> _extractResults(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }
    if (decoded is Map<String, dynamic>) {
      final candidates = [
        decoded['results'],
        decoded['data'],
        decoded['challenges'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
        }
      }
    }
    return const <Map<String, dynamic>>[];
  }
}
