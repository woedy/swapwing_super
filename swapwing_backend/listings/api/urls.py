from rest_framework.routers import DefaultRouter

from listings.api.view import ListingViewSet

app_name = "listings"

router = DefaultRouter()
router.register(r"", ListingViewSet, basename="listing")

urlpatterns = router.urls
