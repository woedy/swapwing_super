"""Serializers for challenge discovery, enrollment, and leaderboard updates."""

from __future__ import annotations

from typing import List, Optional, Sequence, Set

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import serializers

from challenges.models import (
    Challenge,
    ChallengeStatus,
    ChallengeMilestone,
    ChallengeParticipation,
    ChallengePrize,
    ChallengeProgress,
)
from journeys.models import Journey, JourneyStep

User = get_user_model()


def _avatar_url_for(user: User) -> str:
    personal = getattr(user, "user_personal_info", None)
    photo = getattr(personal, "photo", None)
    if photo:
        try:
            return photo.url  # type: ignore[return-value]
        except ValueError:  # pragma: no cover - storage misconfiguration edge
            return ""
    return ""


def _display_name_for(user: User) -> str:
    parts = [user.first_name or "", user.last_name or ""]
    full_name = " ".join(part for part in parts if part).strip()
    return full_name or user.email


class ChallengeMilestoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChallengeMilestone
        fields = ["id", "label", "target_value", "order"]
        read_only_fields = fields


class ChallengePrizeSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChallengePrize
        fields = ["id", "name", "description", "rank_start", "rank_end", "order"]
        read_only_fields = fields


class ChallengeLeaderboardEntrySerializer(serializers.Serializer):
    participant_id = serializers.UUIDField()
    user_id = serializers.UUIDField()
    display_name = serializers.CharField()
    avatar_url = serializers.CharField(allow_blank=True)
    total_trade_delta = serializers.DecimalField(max_digits=12, decimal_places=2)
    rank = serializers.IntegerField()
    journey_id = serializers.UUIDField(allow_null=True)
    trades_completed = serializers.IntegerField()
    last_progress_at = serializers.DateTimeField(allow_null=True)


class ChallengeSummarySerializer(serializers.ModelSerializer):
    participant_count = serializers.IntegerField(read_only=True)
    is_enrolled = serializers.SerializerMethodField()

    class Meta:
        model = Challenge
        fields = [
            "id",
            "title",
            "description",
            "cta_copy",
            "cover_image_url",
            "banner_image_url",
            "status",
            "category",
            "start_at",
            "end_at",
            "participant_count",
            "is_enrolled",
        ]
        read_only_fields = fields

    def get_is_enrolled(self, challenge: Challenge) -> bool:
        enrolled_ids: Set[str] = self.context.get("enrolled_challenge_ids", set())
        return str(challenge.id) in enrolled_ids


class ChallengeDetailSerializer(ChallengeSummarySerializer):
    milestones = ChallengeMilestoneSerializer(many=True, read_only=True)
    prizes = ChallengePrizeSerializer(many=True, read_only=True)
    leaderboard = serializers.SerializerMethodField()
    user_rank = serializers.SerializerMethodField()

    class Meta(ChallengeSummarySerializer.Meta):
        fields = ChallengeSummarySerializer.Meta.fields + [
            "milestones",
            "prizes",
            "leaderboard",
            "user_rank",
        ]

    def _leaderboard_entries(self) -> Sequence[dict]:
        entries = self.context.get("leaderboard_entries") or []
        return entries

    def get_leaderboard(self, challenge: Challenge) -> List[dict]:
        return list(self._leaderboard_entries())

    def get_user_rank(self, challenge: Challenge) -> Optional[dict]:
        current = self.context.get("current_participation")
        if not current:
            return None
        return {
            "participant_id": str(current["participant_id"]),
            "rank": current["rank"],
            "total_trade_delta": current["total_trade_delta"],
        }


class ChallengeParticipationSerializer(serializers.ModelSerializer):
    challenge_id = serializers.UUIDField(source="challenge.id", read_only=True)
    user_id = serializers.UUIDField(source="user.id", read_only=True)
    journey_id = serializers.UUIDField(source="journey.id", read_only=True)
    rank = serializers.IntegerField(read_only=True)

    class Meta:
        model = ChallengeParticipation
        fields = [
            "id",
            "challenge_id",
            "user_id",
            "journey_id",
            "total_trade_delta",
            "trades_completed",
            "last_progress_at",
            "rank",
        ]
        read_only_fields = fields


class ChallengeEnrollRequestSerializer(serializers.Serializer):
    journey_id = serializers.UUIDField(required=False)

    def validate(self, attrs):
        request = self.context["request"]
        challenge: Challenge = self.context["challenge"]
        user: User = request.user
        participation = ChallengeParticipation.objects.filter(
            challenge=challenge, user=user
        ).first()
        attrs["existing_participation"] = participation

        if challenge.status == ChallengeStatus.COMPLETED:
            raise serializers.ValidationError("Challenge already completed")

        journey_id = attrs.get("journey_id")
        journey = None
        if journey_id:
            try:
                journey = Journey.objects.get(id=journey_id)
            except Journey.DoesNotExist as exc:
                raise serializers.ValidationError(
                    {"journey_id": "Journey not found"}
                ) from exc
            if journey.owner_id != user.id:
                raise serializers.ValidationError(
                    {"journey_id": "You can only link journeys you own."}
                )
            attrs["journey"] = journey
        else:
            attrs["journey"] = None

        if participation and journey and participation.journey_id not in {None, journey.id}:
            raise serializers.ValidationError(
                {"journey_id": "Journey is already linked to this enrollment."}
            )

        if not participation and journey:
            exists = ChallengeParticipation.objects.filter(journey=journey).exists()
            if exists:
                raise serializers.ValidationError(
                    {"journey_id": "Journey is already linked to another challenge."}
                )
        return attrs

    def create_participation(self, journey: Optional[Journey]) -> ChallengeParticipation:
        challenge: Challenge = self.context["challenge"]
        user: User = self.context["request"].user
        participation = ChallengeParticipation.objects.create(
            challenge=challenge,
            user=user,
            journey=journey,
        )
        return participation


class ChallengeProgressSerializer(serializers.Serializer):
    journey_id = serializers.UUIDField(required=False)
    step_id = serializers.UUIDField(required=False)
    trade_delta_value = serializers.DecimalField(max_digits=12, decimal_places=2)
    notes = serializers.CharField(required=False, allow_blank=True, max_length=1000)

    def validate_trade_delta_value(self, value):
        if value <= 0:
            raise serializers.ValidationError("Progress must be greater than zero.")
        return value

    def validate(self, attrs):
        challenge: Challenge = self.context["challenge"]
        user: User = self.context["request"].user

        journey_id = attrs.get("journey_id")
        step_id = attrs.get("step_id")

        try:
            participation = ChallengeParticipation.objects.get(
                challenge=challenge, user=user
            )
        except ChallengeParticipation.DoesNotExist as exc:
            raise serializers.ValidationError("You must enroll before submitting progress.") from exc

        journey = participation.journey
        if journey_id:
            try:
                requested_journey = Journey.objects.get(id=journey_id)
            except Journey.DoesNotExist as exc:
                raise serializers.ValidationError({"journey_id": "Journey not found."}) from exc
            if requested_journey.owner_id != user.id:
                raise serializers.ValidationError({"journey_id": "Journey does not belong to you."})
            if journey and requested_journey.id != journey.id:
                raise serializers.ValidationError(
                    {"journey_id": "Enrollment is linked to a different journey."}
                )
            journey = requested_journey
        attrs["journey"] = journey

        journey_step = None
        if step_id:
            try:
                journey_step = JourneyStep.objects.select_related("journey").get(id=step_id)
            except JourneyStep.DoesNotExist as exc:
                raise serializers.ValidationError({"step_id": "Journey step not found."}) from exc
            if journey and journey_step.journey_id != journey.id:
                raise serializers.ValidationError(
                    {"step_id": "Step does not belong to the linked journey."}
                )
            if journey_step.journey.owner_id != user.id:
                raise serializers.ValidationError(
                    {"step_id": "You can only submit your own journey steps."}
                )
        attrs["journey_step"] = journey_step
        attrs["participation"] = participation
        return attrs

    def save(self) -> ChallengeProgress:
        participation: ChallengeParticipation = self.validated_data["participation"]
        journey_step: Optional[JourneyStep] = self.validated_data["journey_step"]
        trade_delta_value = self.validated_data["trade_delta_value"]
        notes = self.validated_data.get("notes", "")

        progress = ChallengeProgress.objects.create(
            participation=participation,
            journey_step=journey_step,
            trade_delta_value=trade_delta_value,
            notes=notes,
        )

        participation.total_trade_delta += trade_delta_value
        if journey_step:
            participation.trades_completed += 1
            participation.last_step = journey_step
        participation.last_progress_at = timezone.now()
        participation.save(update_fields=[
            "total_trade_delta",
            "trades_completed",
            "last_progress_at",
            "last_step",
            "updated_at",
        ])

        return progress
