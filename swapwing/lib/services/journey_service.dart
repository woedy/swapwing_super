import 'dart:async';

import 'package:swapwing/config/environment.dart';
import 'package:swapwing/models/journey_draft.dart';
import 'package:swapwing/models/trade_journey.dart';
import 'package:swapwing/services/sample_data.dart';

class JourneyServiceException implements Exception {
  final String message;

  const JourneyServiceException(this.message);

  @override
  String toString() => 'JourneyServiceException: $message';
}

/// Handles loading, persisting, and publishing trade journey drafts.
class JourneyService {
  const JourneyService();

  Future<List<TradeJourney>> fetchMyJourneys() async {
    if (EnvironmentConfig.useMockData) {
      return SampleData.getJourneysForUser(SampleData.currentUser.id);
    }

    // TODO: Implement live API fetching once backend endpoints are available.
    throw const JourneyServiceException(
      'Live journey APIs are not yet available in this environment.',
    );
  }

  Future<List<JourneyDraft>> fetchDrafts() async {
    if (EnvironmentConfig.useMockData) {
      return SampleData.getJourneyDrafts();
    }

    throw const JourneyServiceException(
      'Live journey APIs are not yet available in this environment.',
    );
  }

  Future<JourneyDraft> saveDraft(JourneyDraft draft) async {
    if (EnvironmentConfig.useMockData) {
      final normalized = draft.copyWith(touchUpdatedAt: true);
      SampleData.saveJourneyDraft(normalized);
      return normalized;
    }

    throw const JourneyServiceException(
      'Saving journey drafts requires the live backend.',
    );
  }

  Future<void> deleteDraft(String id) async {
    if (EnvironmentConfig.useMockData) {
      SampleData.removeJourneyDraft(id);
      return;
    }

    throw const JourneyServiceException(
      'Deleting journey drafts requires the live backend.',
    );
  }

  Future<TradeJourney> publishJourney(JourneyDraft draft) async {
    if (EnvironmentConfig.useMockData) {
      final owner = SampleData.currentUser;
      final now = DateTime.now();
      final listing = draft.startingListing ??
          SampleData.findListingById(draft.startingListingId ?? '');
      final journey = draft
          .copyWith(
            title: (draft.title ?? '').trim(),
            description: draft.description?.trim(),
            startingListing: listing,
            startingListingId: draft.startingListingId ?? listing?.id,
            startingValue: draft.startingValue ?? listing?.estimatedValue,
            touchUpdatedAt: true,
          )
          .toTradeJourney(owner)
          .copyWith(
            id: 'journey_${now.millisecondsSinceEpoch}',
            createdAt: now,
            likes: 0,
          );

      SampleData.addJourney(journey);
      SampleData.removeJourneyDraft(draft.id);
      return journey;
    }

    throw const JourneyServiceException(
      'Publishing journeys requires the live backend.',
    );
  }
}
