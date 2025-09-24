from django.db.models import Prefetch, Q
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import (
    OpenApiParameter,
    OpenApiResponse,
    OpenApiTypes,
    extend_schema,
    extend_schema_view,
    inline_serializer,
)
from rest_framework import mixins, permissions, serializers, status, viewsets
from rest_framework.authentication import TokenAuthentication
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response

from journeys.api.serializers import JourneySerializer, JourneyStepSerializer
from journeys.models import (
    Journey,
    JourneyFollower,
    JourneyStatus,
    JourneyStep,
    JourneyStepStatus,
    JourneyVisibility,
)


class IsJourneyOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj: Journey):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.owner_id == request.user.id


@extend_schema_view(
    list=extend_schema(
        summary="Discover journeys",
        description="Return journeys the trader can see with filtering for owner, "
        "status, and follow relationships.",
        parameters=[
            OpenApiParameter(
                name="owner",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Filter by owner. Use `me` to scope to the authenticated trader.",
            ),
            OpenApiParameter(
                name="status",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                many=True,
                description="Filter by journey status (draft, live, completed).",
            ),
            OpenApiParameter(
                name="following",
                type=OpenApiTypes.BOOL,
                location=OpenApiParameter.QUERY,
                description="When true, only include journeys the trader follows.",
            ),
            OpenApiParameter(
                name="search",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Keyword search across the journey title, description, and tags.",
            ),
            OpenApiParameter(
                name="ordering",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Comma separated ordering fields (defaults to `-created_at`).",
            ),
            OpenApiParameter(
                name="include_steps",
                type=OpenApiTypes.BOOL,
                location=OpenApiParameter.QUERY,
                description="Include serialized steps in the list response. Defaults to false for performance.",
            ),
        ],
        tags=["Journeys"],
    ),
    retrieve=extend_schema(summary="Retrieve a journey", tags=["Journeys"]),
    create=extend_schema(summary="Create a journey", tags=["Journeys"]),
    update=extend_schema(summary="Update a journey", tags=["Journeys"]),
    partial_update=extend_schema(summary="Partially update a journey", tags=["Journeys"]),
    destroy=extend_schema(summary="Delete a journey", tags=["Journeys"]),
)
class JourneyViewSet(viewsets.ModelViewSet):
    serializer_class = JourneySerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated, IsJourneyOwnerOrReadOnly]

    def get_permissions(self):
        if self.action in {"list", "retrieve", "follow"}:
            permission_classes = [permissions.IsAuthenticated]
        else:
            permission_classes = [permissions.IsAuthenticated, IsJourneyOwnerOrReadOnly]
        return [permission() for permission in permission_classes]

    def get_queryset(self):
        user = self.request.user
        queryset = (
            Journey.objects.select_related("owner", "starting_listing")
            .prefetch_related(
                Prefetch("steps", queryset=JourneyStep.objects.prefetch_related("media")),
                "followers",
            )
        )

        if user.is_authenticated:
            visibility_filter = Q(visibility=JourneyVisibility.PUBLIC) | Q(owner=user)
            visibility_filter |= Q(visibility=JourneyVisibility.FOLLOWERS, followers=user)
        else:
            visibility_filter = Q(visibility=JourneyVisibility.PUBLIC)

        queryset = queryset.filter(visibility_filter)
        return queryset.distinct()

    def filter_queryset(self, queryset):
        params = self.request.query_params

        owner_param = params.get("owner") or params.get("owner_id")
        if owner_param == "me":
            queryset = queryset.filter(owner=self.request.user)
        elif owner_param:
            queryset = queryset.filter(owner__user_id=owner_param)

        statuses = params.getlist("status") or []
        if statuses:
            queryset = queryset.filter(status__in=statuses)

        following = params.get("following")
        if following and str(following).lower() in {"1", "true", "yes"}:
            queryset = queryset.filter(followers=self.request.user)

        search = params.get("search")
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search)
                | Q(description__icontains=search)
                | Q(tags__icontains=search)
            )

        ordering = params.get("ordering")
        if ordering:
            queryset = queryset.order_by(*[term.strip() for term in ordering.split(",") if term.strip()])
        else:
            queryset = queryset.order_by("-created_at")

        return queryset.distinct()

    def get_serializer_context(self):
        context = super().get_serializer_context()
        include_steps = self.action == "retrieve" or self.request.query_params.get("include_steps") in {
            "1",
            "true",
            "True",
        }
        context["include_steps"] = include_steps
        return context

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    @extend_schema(
        summary="Publish all draft steps",
        description="Promote every draft step in the journey to published and mark the journey as live.",
        request=None,
        responses={
            status.HTTP_200_OK: inline_serializer(
                name="JourneyPublishResponse",
                fields={
                    "published": serializers.BooleanField(),
                    "steps_updated": serializers.IntegerField(),
                },
            )
        },
        tags=["Journeys"],
    )
    @action(detail=True, methods=["post"], url_path="publish")
    def publish(self, request, pk=None):
        journey = self.get_object()
        if journey.owner_id != request.user.id:
            raise PermissionDenied("You cannot publish someone else's journey.")

        updated_steps = journey.steps.filter(status=JourneyStepStatus.DRAFT)
        count = updated_steps.update(status=JourneyStepStatus.PUBLISHED)
        journey.mark_published()
        return Response({"published": True, "steps_updated": count})

    @extend_schema(
        summary="Follow or unfollow a journey",
        description="POST to follow a journey or DELETE to remove the follow relationship.",
        request=None,
        responses={
            status.HTTP_200_OK: inline_serializer(
                name="JourneyFollowResponse",
                fields={"following": serializers.BooleanField()},
            ),
            status.HTTP_204_NO_CONTENT: OpenApiResponse(description="Unfollowed successfully"),
        },
        tags=["Journeys"],
    )
    @action(detail=True, methods=["post", "delete"], url_path="follow")
    def follow(self, request, pk=None):
        journey = self.get_object()
        if request.method.lower() == "post":
            JourneyFollower.objects.get_or_create(journey=journey, user=request.user)
            return Response({"following": True})
        JourneyFollower.objects.filter(journey=journey, user=request.user).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


@extend_schema_view(
    list=extend_schema(summary="List steps for a journey", tags=["Journey Steps"]),
    create=extend_schema(summary="Create a journey step", tags=["Journey Steps"]),
    retrieve=extend_schema(summary="Retrieve a journey step", tags=["Journey Steps"]),
    partial_update=extend_schema(summary="Update a journey step", tags=["Journey Steps"]),
    destroy=extend_schema(summary="Delete a journey step", tags=["Journey Steps"]),
)
class JourneyStepViewSet(
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.UpdateModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    serializer_class = JourneyStepSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        journey = self.get_journey()
        return (
            JourneyStep.objects.filter(journey=journey)
            .select_related("journey", "from_listing", "to_listing")
            .prefetch_related("media")
            .order_by("sequence")
        )

    def get_journey(self) -> Journey:
        if not hasattr(self, "_journey"):
            journey = get_object_or_404(
                Journey.objects.prefetch_related("followers").select_related("owner"),
                pk=self.kwargs["journey_pk"],
            )
            if not self._user_can_access(journey):
                raise PermissionDenied("You do not have access to this journey.")
            self._journey = journey
        return self._journey

    def _user_can_access(self, journey: Journey) -> bool:
        user = self.request.user
        if journey.owner_id == user.id:
            return True
        if journey.visibility == JourneyVisibility.PUBLIC:
            return True
        if journey.visibility == JourneyVisibility.FOLLOWERS:
            return journey.followers.filter(id=user.id).exists()
        return False

    def _ensure_owner(self):
        journey = self.get_journey()
        if journey.owner_id != self.request.user.id:
            raise PermissionDenied("Only the journey owner can modify steps.")
        return journey

    def perform_create(self, serializer):
        journey = self._ensure_owner()
        serializer.save(journey=journey)

    def perform_update(self, serializer):
        self._ensure_owner()
        serializer.save()

    def perform_destroy(self, instance):
        self._ensure_owner()
        instance.delete()

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["journey"] = self.get_journey()
        return context
