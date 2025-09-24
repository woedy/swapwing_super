from django.urls import include, path
from rest_framework.routers import DefaultRouter

from challenges.api.views import ChallengeViewSet

app_name = "challenges"

router = DefaultRouter()
router.register(r"", ChallengeViewSet, basename="challenge")

urlpatterns = [
    path("", include(router.urls)),
]
