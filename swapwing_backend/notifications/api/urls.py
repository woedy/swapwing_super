from django.urls import path

from notifications.api.views.views import get_user_notification_view

app_name = 'notifications'

urlpatterns = [
    path('user-notifications', get_user_notification_view, name="get_user_notification"),
]
