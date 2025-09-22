from rest_framework import serializers

from trade_up_league.models import Episode


class ListAllEpisodesSerializer(serializers.ModelSerializer):
    class Meta:
        model = Episode
        fields = ['id', 'title', 'caption', 'video', 'date_published', 'tags', 'shared_episodes', 'user', 'likes', 'views','trending_no', 'active']

