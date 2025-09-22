from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.authentication import TokenAuthentication
from rest_framework.decorators import permission_classes, api_view, authentication_classes
from rest_framework.generics import get_object_or_404
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from notifications.api.serializers import NotificationSerializer
from notifications.models import Notification
from trade_up_league.api.serializers import ListAllEpisodesSerializer
from trade_up_league.models import Episode
from user_profile.models import PersonalInfo

User = get_user_model()



@api_view(['GET', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def user_home_view(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'GET':
        user_id = request.query_params.get('user_id', None)

        if not user_id:
            payload['message'] = "Error"
            errors.append("User ID Required.")
        else:

            has_notification = False

            user = get_object_or_404(User, user_id=user_id)
            personal_info = get_object_or_404(PersonalInfo, user=user)

            user_data['first_name'] = user.first_name
            user_data['last_name'] = user.last_name
            user_data['profile_photo'] = personal_info.photo.url

            notifications = Notification.objects.all().filter(user=user)
            notifications_serializer = NotificationSerializer(notifications, many=True)
            if notifications_serializer:
                notifications = notifications_serializer.data

            for notification in notifications:
                if notification['read'] == False:
                    has_notification = True

            data['user_data'] = user_data
            data['has_notification'] = has_notification


            all_episodes = Episode.objects.all().order_by("trending_no")
            all_episodes_serializer = ListAllEpisodesSerializer(all_episodes, many=True)
            if all_episodes_serializer:
                all_episodes = all_episodes_serializer.data

            data['all_episodes'] = all_episodes



        payload['response'] = "Successful"
        payload['data'] = data

        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        return Response(payload, status=status.HTTP_200_OK)

