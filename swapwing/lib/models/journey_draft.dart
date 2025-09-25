import 'package:swapwing/models/listing.dart';
import 'package:swapwing/models/trade_journey.dart';
import 'package:swapwing/models/user.dart';

/// A lightweight representation of a trade journey that has not yet been
/// published. Drafts power the multi-step composer and allow users to iterate
/// on their story before sharing it broadly.
class JourneyDraft {
  final String id;
  final String? title;
  final String? description;
  final SwapListing? startingListing;
  final String? startingListingId;
  final double? startingValue;
  final double? targetValue;
  final List<JourneyDraftStep> steps;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JourneyDraft({
    required this.id,
    this.title,
    this.description,
    this.startingListing,
    this.startingListingId,
    this.startingValue,
    this.targetValue,
    this.steps = const [],
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an empty draft with a generated identifier.
  factory JourneyDraft.empty() {
    final now = DateTime.now();
    return JourneyDraft(
      id: 'draft_${now.millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Whether the draft has enough information to be published.
  bool get isPublishable {
    final hasTitle = (title ?? '').trim().isNotEmpty;
    final hasStartingItem = (startingListingId ?? startingListing?.id)?.isNotEmpty ?? false;
    final hasTargetValue = targetValue != null && (targetValue ?? 0) > 0;
    return hasTitle && hasStartingItem && hasTargetValue;
  }

  /// Returns a sanitized list of tags without duplicates or empty entries.
  List<String> get normalizedTags {
    final seen = <String>{};
    final cleaned = <String>[];
    for (final tag in tags) {
      final normalized = tag.trim();
      if (normalized.isEmpty) continue;
      if (seen.add(normalized.toLowerCase())) {
        cleaned.add(normalized);
      }
    }
    return cleaned;
  }

  JourneyDraft copyWith({
    String? id,
    String? title,
    String? description,
    SwapListing? startingListing,
    String? startingListingId,
    double? startingValue,
    double? targetValue,
    List<JourneyDraftStep>? steps,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool touchUpdatedAt = false,
  }) {
    return JourneyDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startingListing: startingListing ?? this.startingListing,
      startingListingId: startingListingId ?? this.startingListingId ?? startingListing?.id,
      startingValue: startingValue ?? this.startingValue,
      targetValue: targetValue ?? this.targetValue,
      steps: steps ?? this.steps,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: touchUpdatedAt ? DateTime.now() : (updatedAt ?? this.updatedAt),
    );
  }

  /// Converts the draft into a [TradeJourney] suitable for previews or mock
  /// publishing flows. Planned steps that are not marked as completed are
  /// omitted from the final payload.
  TradeJourney toTradeJourney(SwapWingUser owner) {
    final now = DateTime.now();
    final effectiveStartingListingId =
        startingListingId ?? startingListing?.id ?? 'draft_start_${owner.id}_${now.millisecondsSinceEpoch}';
    final effectiveStartingValue = startingValue ?? startingListing?.estimatedValue ?? 0;

    final completedSteps = steps.where((step) => step.isCompleted).toList();
    final generatedSteps = <TradeStep>[];

    var previousValue = effectiveStartingValue;
    var previousListingId = effectiveStartingListingId;

    for (var index = 0; index < completedSteps.length; index++) {
      final step = completedSteps[index];
      final toValue = step.targetValue ?? previousValue;
      final stepId = '${id}_step_${index + 1}';
      final targetListingId = '${stepId}_item';

      generatedSteps.add(
        TradeStep(
          id: stepId,
          fromListingId: previousListingId,
          toListingId: targetListingId,
          fromValue: previousValue,
          toValue: toValue,
          completedAt: step.completedAt ?? now,
          notes: step.notes?.trim().isEmpty ?? true ? null : step.notes?.trim(),
        ),
      );

      previousValue = toValue;
      previousListingId = targetListingId;
    }

    return TradeJourney(
      id: 'journey_preview_${id}_${now.millisecondsSinceEpoch}',
      userId: owner.id,
      userName: owner.username,
      userAvatar: owner.profileImageUrl,
      title: (title ?? '').trim().isEmpty ? 'Untitled Journey' : title!.trim(),
      description: description?.trim().isEmpty ?? true ? null : description!.trim(),
      startingListingId: effectiveStartingListingId,
      startingValue: effectiveStartingValue,
      targetValue: targetValue ?? effectiveStartingValue,
      tradeSteps: generatedSteps,
      status: TradeJourneyStatus.active,
      createdAt: now,
      likes: 0,
      comments: 0,
      shares: 0,
      isLikedByCurrentUser: false,
      tags: normalizedTags,
    );
  }
}

/// Representation of a single step within a [JourneyDraft].
class JourneyDraftStep {
  final String id;
  final String title;
  final String? notes;
  final double? targetValue;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  const JourneyDraftStep({
    required this.id,
    required this.title,
    this.notes,
    this.targetValue,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  JourneyDraftStep copyWith({
    String? id,
    String? title,
    String? notes,
    double? targetValue,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return JourneyDraftStep(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      targetValue: targetValue ?? this.targetValue,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  JourneyDraftStep markCompleted(bool completed) {
    if (!completed) {
      return copyWith(isCompleted: false, completedAt: null);
    }
    return copyWith(isCompleted: true, completedAt: completedAt ?? DateTime.now());
  }
}
