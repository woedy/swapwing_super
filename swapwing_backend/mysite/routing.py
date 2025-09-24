from django.urls import re_path

from challenges.consumers import ChallengeLeaderboardConsumer

websocket_urlpatterns = [
    re_path(
        r"^ws/challenges/(?P<challenge_id>[0-9a-f\-]+)/leaderboard/$",
        ChallengeLeaderboardConsumer.as_asgi(),
    ),
]
