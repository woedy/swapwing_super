"""Viewsets powering the challenge discovery and engagement API."""

from __future__ import annotations

from typing import List, Sequence

from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db.models import Count, QuerySet
from drf_spectacular.utils import (
    OpenApiParameter,
    OpenApiResponse,
    OpenApiTypes,
    extend_schema,
    extend_schema_view,
    inline_serializer,
)
from rest_framework import mixins, serializers, status, viewsets
from rest_framework.authentication import TokenAuthentication
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from challenges.api.serializers import (
    ChallengeDetailSerializer,
    ChallengeEnrollRequestSerializer,
    ChallengeLeaderboardEntrySerializer,
    ChallengeParticipationSerializer,
    ChallengeProgressSerializer,
    ChallengeSummarySerializer,
    _avatar_url_for,
    _display_name_for,
)
from challenges.models import Challenge, ChallengeParticipation, ChallengeStatus


@extend_schema_view(
    list=extend_schema(
        summary="Browse community challenges",
        description="Return active, upcoming, or completed challenges with basic summary information.",
        parameters=[
            OpenApiParameter(
                name="status",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Filter by challenge status (UPCOMING, ACTIVE, COMPLETED).",
            ),
            OpenApiParameter(
                name="category",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Filter challenges by category slug.",
            ),
            OpenApiParameter(
                name="enrolled",
                type=OpenApiTypes.BOOL,
                location=OpenApiParameter.QUERY,
                description="When true, only return challenges the authenticated trader has joined.",
            ),
        ],
        tags=["Challenges"],
    ),
    retrieve=extend_schema(summary="Retrieve a challenge", tags=["Challenges"]),
)
class ChallengeViewSet(mixins.ListModelMixin, mixins.RetrieveModelMixin, viewsets.GenericViewSet):
    """Expose challenge discovery plus enrollment and progress actions."""

    serializer_class = ChallengeSummarySerializer
    queryset = Challenge.objects.all()
    authentication_classes = [TokenAuthentication]

    def get_queryset(self) -> QuerySet:
        base = (
            Challenge.objects.all()
            .annotate(participant_count=Count("participations", distinct=True))
            .prefetch_related("milestones", "prizes")
            .order_by("-start_at", "title")
        )
        status_param = self.request.query_params.get("status")
        if status_param in {choice[0] for choice in ChallengeStatus.choices}:
            base = base.filter(status=status_param)

        category = self.request.query_params.get("category")
        if category:
            base = base.filter(category=category)

        enrolled = self.request.query_params.get("enrolled")
        if enrolled and self.request.user.is_authenticated:
            truthy = {"1", "true", "yes", "on"}
            if enrolled.lower() in truthy:
                base = base.filter(participations__user=self.request.user)
        elif enrolled and not self.request.user.is_authenticated:
            return base.none()

        return base.distinct()

    def get_serializer_class(self):
        if self.action == "retrieve":
            return ChallengeDetailSerializer
        return super().get_serializer_class()

    # -- helpers -----------------------------------------------------------------
    def _serializer_context_for(self, data: Sequence[Challenge]):
        context = self.get_serializer_context()
        if isinstance(data, QuerySet):
            challenge_ids = list(data.values_list("id", flat=True))
        else:
            challenge_ids = [challenge.id for challenge in data]

        if self.request.user.is_authenticated and challenge_ids:
            enrolled_ids = set(
                ChallengeParticipation.objects.filter(
                    challenge_id__in=challenge_ids,
                    user=self.request.user,
                ).values_list("challenge_id", flat=True)
            )
        else:
            enrolled_ids = set()
        context["enrolled_challenge_ids"] = {str(value) for value in enrolled_ids}
        return context

    def _all_participations(self, challenge: Challenge) -> List[ChallengeParticipation]:
        return list(
            challenge.participations.select_related("user", "journey")
            .order_by("-total_trade_delta", "joined_at")
        )

    def _leaderboard_for(self, challenge: Challenge):
        participations = self._all_participations(challenge)
        leaderboard = []
        current_participation = None
        for idx, participation in enumerate(participations, start=1):
            if idx <= 20:
                leaderboard.append(
                    {
                        "participant_id": participation.id,
                        "user_id": participation.user_id,
                        "display_name": _display_name_for(participation.user),
                        "avatar_url": _avatar_url_for(participation.user),
                        "total_trade_delta": participation.total_trade_delta,
                        "rank": idx,
                        "journey_id": participation.journey_id,
                        "trades_completed": participation.trades_completed,
                        "last_progress_at": participation.last_progress_at,
                    }
                )
            if (
                self.request.user.is_authenticated
                and participation.user_id == self.request.user.id
            ):
                current_participation = {
                    "participant_id": participation.id,
                    "rank": idx,
                    "total_trade_delta": participation.total_trade_delta,
                }
        return leaderboard, current_participation

    def _broadcast_leaderboard(self, challenge: Challenge, payload: dict):
        channel_layer = get_channel_layer()
        if not channel_layer:
            return
        async_to_sync(channel_layer.group_send)(
            f"challenge_{challenge.id}",
            {"type": "leaderboard.update", "payload": payload},
        )

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())

        page = self.paginate_queryset(queryset)
        if page is not None:
            context = self._serializer_context_for(page)
            serializer = self.get_serializer(page, many=True, context=context)
            return self.get_paginated_response(serializer.data)

        context = self._serializer_context_for(queryset)
        serializer = self.get_serializer(queryset, many=True, context=context)
        return Response(serializer.data)

    def retrieve(self, request, *args, **kwargs):
        challenge = self.get_object()
        leaderboard, current = self._leaderboard_for(challenge)
        serializer = self.get_serializer(
            challenge,
            context={
                **self._serializer_context_for([challenge]),
                "leaderboard_entries": ChallengeLeaderboardEntrySerializer(
                    leaderboard, many=True
                ).data,
                "current_participation": current,
            },
        )
        return Response(serializer.data)

    def _rank_for_participation(
        self, challenge: Challenge, participation: ChallengeParticipation
    ) -> int:
        for idx, record in enumerate(self._all_participations(challenge), start=1):
            if record.id == participation.id:
                return idx
        return 0

    @extend_schema(
        summary="Enroll in a challenge",
        description="POST to enroll (or update the linked journey) and DELETE to leave the challenge.",
        request=ChallengeEnrollRequestSerializer,
        responses={
            status.HTTP_201_CREATED: ChallengeParticipationSerializer,
            status.HTTP_200_OK: ChallengeParticipationSerializer,
            status.HTTP_204_NO_CONTENT: OpenApiResponse(description="Left the challenge"),
            status.HTTP_409_CONFLICT: OpenApiResponse(
                description="Journey already enrolled in another challenge."
            ),
        },
        tags=["Challenges"],
    )
    @action(detail=True, methods=["post", "delete"], permission_classes=[IsAuthenticated])
    def enroll(self, request, *args, **kwargs):
        challenge = self.get_object()

        if request.method.lower() == "delete":
            deleted, _ = ChallengeParticipation.objects.filter(
                challenge=challenge, user=request.user
            ).delete()
            if not deleted:
                return Response(status=status.HTTP_404_NOT_FOUND)
            return Response(status=status.HTTP_204_NO_CONTENT)

        serializer = ChallengeEnrollRequestSerializer(
            data=request.data,
            context={"request": request, "challenge": challenge},
        )
        if not serializer.is_valid():
            errors = serializer.errors
            journey_errors = errors.get("journey_id", [])
            conflict = any(
                "another challenge" in str(message) for message in journey_errors
            )
            if conflict:
                return Response(errors, status=status.HTTP_409_CONFLICT)
            raise ValidationError(errors)
        participation: ChallengeParticipation = serializer.validated_data.get(
            "existing_participation"
        )
        created = False
        if participation:
            new_journey = serializer.validated_data.get("journey")
            if new_journey and participation.journey_id != new_journey.id:
                participation.journey = new_journey
                participation.save(update_fields=["journey", "updated_at"])
        else:
            participation = serializer.create_participation(
                serializer.validated_data.get("journey")
            )
            created = True

        participation.rank = self._rank_for_participation(challenge, participation)
        response_data = ChallengeParticipationSerializer(participation).data
        status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        if not created:
            response_data["code"] = "ALREADY_ENROLLED"
        return Response(response_data, status=status_code)

    @extend_schema(
        summary="Submit challenge progress",
        request=ChallengeProgressSerializer,
        responses={
            status.HTTP_202_ACCEPTED: inline_serializer(
                name="ChallengeProgressResponse",
                fields={
                    "progress_id": serializers.UUIDField(),
                    "rank": serializers.IntegerField(),
                    "total_trade_delta": serializers.CharField(),
                },
            )
        },
        tags=["Challenges"],
    )
    @action(detail=True, methods=["post"], permission_classes=[IsAuthenticated])
    def progress(self, request, *args, **kwargs):
        challenge = self.get_object()
        serializer = ChallengeProgressSerializer(
            data=request.data,
            context={"request": request, "challenge": challenge},
        )
        serializer.is_valid(raise_exception=True)
        progress = serializer.save()
        participation = progress.participation
        rank = self._rank_for_participation(challenge, participation)

        payload = {
            "challenge_id": str(challenge.id),
            "participant_id": str(participation.id),
            "rank": rank,
            "total_trade_delta": str(participation.total_trade_delta),
            "updated_at": participation.last_progress_at.isoformat()
            if participation.last_progress_at
            else None,
        }
        self._broadcast_leaderboard(challenge, payload)

        return Response(
            {
                "progress_id": str(progress.id),
                "rank": rank,
                "total_trade_delta": str(participation.total_trade_delta),
            },
            status=status.HTTP_202_ACCEPTED,
        )
