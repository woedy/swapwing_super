"""Websocket consumer streaming challenge leaderboard updates."""

from __future__ import annotations

from asgiref.sync import sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer

from challenges.models import Challenge


class ChallengeLeaderboardConsumer(AsyncJsonWebsocketConsumer):
    group_name: str

    async def connect(self):
        challenge_id = self.scope["url_route"]["kwargs"].get("challenge_id")
        exists = await sync_to_async(Challenge.objects.filter(id=challenge_id).exists)()
        if not exists:
            await self.close(code=4404)
            return
        self.group_name = f"challenge_{challenge_id}"
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, code):
        if hasattr(self, "group_name"):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def leaderboard_update(self, event):
        await self.send_json(event.get("payload", {}))
