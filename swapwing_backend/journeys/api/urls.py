from django.urls import include, path
from rest_framework.routers import DefaultRouter

from journeys.api.views import JourneyStepViewSet, JourneyViewSet

app_name = "journeys"

router = DefaultRouter()
router.register(r"", JourneyViewSet, basename="journey")

step_list = JourneyStepViewSet.as_view({"get": "list", "post": "create"})
step_detail = JourneyStepViewSet.as_view(
    {"get": "retrieve", "patch": "partial_update", "delete": "destroy"}
)

urlpatterns = [
    path("", include(router.urls)),
    path("<uuid:journey_pk>/steps/", step_list, name="journey-step-list"),
    path("<uuid:journey_pk>/steps/<uuid:pk>/", step_detail, name="journey-step-detail"),
]
