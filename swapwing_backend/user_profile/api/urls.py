from django.urls import path

from user_profile.api.views import ProfileDetailView, ProfileMeView

app_name = 'user_profile'

urlpatterns = [
    path("me/", ProfileMeView.as_view(), name="profile_me"),
    path("<str:user_id>/", ProfileDetailView.as_view(), name="profile_detail"),
]
