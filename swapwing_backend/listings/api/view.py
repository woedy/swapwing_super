from decimal import Decimal, InvalidOperation

from django.db.models import Q
from drf_spectacular.utils import (
    OpenApiParameter,
    OpenApiTypes,
    extend_schema,
    extend_schema_view,
)
from rest_framework import permissions, viewsets
from rest_framework.authentication import TokenAuthentication
from rest_framework.exceptions import ValidationError

from listings.api.serializers import ListingSerializer
from listings.models import Listing, ListingStatus


class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj: Listing):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.owner_id == request.user.id


@extend_schema_view(
    list=extend_schema(
        summary="Browse marketplace listings",
        description="Return marketplace listings with optional search, category, "
        "status, and valuation filters.",
        parameters=[
            OpenApiParameter(
                name="search",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Keyword search across title, description, tags, and location.",
            ),
            OpenApiParameter(
                name="category",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Filter by one or more listing categories.",
                many=True,
            ),
            OpenApiParameter(
                name="status",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Filter by listing status (defaults to active listings only).",
                many=True,
            ),
            OpenApiParameter(
                name="trade_up_eligible",
                type=OpenApiTypes.BOOL,
                location=OpenApiParameter.QUERY,
                description="Limit results to listings marked as part of trade-up journeys.",
            ),
            OpenApiParameter(
                name="min_value",
                type=OpenApiTypes.DECIMAL,
                location=OpenApiParameter.QUERY,
                description="Return listings with an estimated value greater than or equal to this amount.",
            ),
            OpenApiParameter(
                name="max_value",
                type=OpenApiTypes.DECIMAL,
                location=OpenApiParameter.QUERY,
                description="Return listings with an estimated value less than or equal to this amount.",
            ),
            OpenApiParameter(
                name="owner",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Filter by owner. Use `me` to scope to the authenticated trader.",
            ),
            OpenApiParameter(
                name="ordering",
                type=OpenApiTypes.STR,
                location=OpenApiParameter.QUERY,
                description="Comma separated list of fields to order by (e.g. `-created_at`).",
            ),
        ],
        tags=["Listings"],
    ),
    retrieve=extend_schema(summary="Retrieve a listing", tags=["Listings"]),
    create=extend_schema(summary="Create a listing", tags=["Listings"]),
    update=extend_schema(summary="Update a listing", tags=["Listings"]),
    partial_update=extend_schema(summary="Partially update a listing", tags=["Listings"]),
    destroy=extend_schema(
        summary="Delete a listing",
        description="Soft delete the listing so it no longer appears in discovery feeds.",
        tags=["Listings"],
    ),
)
class ListingViewSet(viewsets.ModelViewSet):
    serializer_class = ListingSerializer
    authentication_classes = [TokenAuthentication]
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_queryset(self):
        queryset = Listing.objects.select_related("owner").prefetch_related("media")

        if self.action == "list":
            queryset = queryset.exclude(status=ListingStatus.DELETED)

        return queryset

    def filter_queryset(self, queryset):
        params = self.request.query_params
        errors = {}

        search = params.get("search")
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search)
                | Q(description__icontains=search)
                | Q(tags__icontains=search)
                | Q(location__icontains=search)
            )

        categories = params.getlist("category") or []
        if categories:
            queryset = queryset.filter(category__in=categories)

        status_filter = params.getlist("status") or []
        if status_filter:
            queryset = queryset.filter(status__in=status_filter)

        trade_up = params.get("trade_up_eligible")
        if trade_up is not None:
            trade_up_bool = str(trade_up).lower() in {"1", "true", "yes"}
            queryset = queryset.filter(is_trade_up_eligible=trade_up_bool)

        min_value = params.get("min_value")
        if min_value:
            try:
                min_decimal = Decimal(min_value)
            except (InvalidOperation, TypeError):
                errors["min_value"] = "Enter a valid number."
            else:
                queryset = queryset.filter(estimated_value__gte=min_decimal)

        max_value = params.get("max_value")
        if max_value:
            try:
                max_decimal = Decimal(max_value)
            except (InvalidOperation, TypeError):
                errors["max_value"] = "Enter a valid number."
            else:
                queryset = queryset.filter(estimated_value__lte=max_decimal)

        owner_param = params.get("owner")
        if owner_param == "me":
            queryset = queryset.filter(owner=self.request.user)
        elif owner_param:
            queryset = queryset.filter(owner__user_id=owner_param)

        if errors:
            raise ValidationError(errors)

        ordering = params.get("ordering")
        if ordering:
            queryset = queryset.order_by(*[term.strip() for term in ordering.split(",") if term.strip()])

        return queryset

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
