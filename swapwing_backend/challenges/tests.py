from datetime import timedelta
from decimal import Decimal
from types import SimpleNamespace
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from challenges.models import (
    Challenge,
    ChallengeCategory,
    ChallengeMilestone,
    ChallengeParticipation,
    ChallengePrize,
    ChallengeProgress,
    ChallengeStatus,
)
from journeys.models import Journey, JourneyStep, JourneyVisibility

User = get_user_model()


class ChallengeAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="alice@example.com",
            password="Password123",
            first_name="Alice",
            last_name="Trader",
        )
        token = Token.objects.get(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")

        now = timezone.now()
        self.challenge = Challenge.objects.create(
            title="Paperclip to House",
            description="Document each trade-up step to climb the leaderboard.",
            cta_copy="Join the story-driven swap challenge!",
            cover_image_url="https://cdn.swapwing.app/challenges/paperclip-thumb.jpg",
            banner_image_url="https://cdn.swapwing.app/challenges/paperclip-banner.jpg",
            status=ChallengeStatus.ACTIVE,
            category=ChallengeCategory.SUSTAINABILITY,
            start_at=now - timedelta(days=3),
            end_at=now + timedelta(days=7),
        )
        ChallengeMilestone.objects.create(
            challenge=self.challenge,
            label="First Trade",
            target_value=Decimal("25.00"),
            order=1,
        )
        ChallengePrize.objects.create(
            challenge=self.challenge,
            name="Grand Prize",
            description="Swap credits and featured story spotlight.",
            rank_start=1,
            rank_end=1,
            order=1,
        )

        self.list_url = reverse("challenges:challenge-list")
        self.detail_url = reverse("challenges:challenge-detail", kwargs={"pk": self.challenge.id})
        self.enroll_url = reverse("challenges:challenge-enroll", kwargs={"pk": self.challenge.id})
        self.progress_url = reverse("challenges:challenge-progress", kwargs={"pk": self.challenge.id})

    def test_list_and_detail_include_leaderboard_and_enrollment(self):
        participation = ChallengeParticipation.objects.create(
            challenge=self.challenge,
            user=self.user,
            total_trade_delta=Decimal("120.00"),
            trades_completed=3,
        )

        list_response = self.client.get(self.list_url)
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(list_response.data), 1)
        summary = list_response.data[0]
        self.assertEqual(summary["id"], str(self.challenge.id))
        self.assertTrue(summary["is_enrolled"])
        self.assertEqual(summary["participant_count"], 1)

        detail_response = self.client.get(self.detail_url)
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        detail = detail_response.data
        self.assertEqual(detail["participant_count"], 1)
        self.assertEqual(len(detail["milestones"]), 1)
        self.assertEqual(len(detail["prizes"]), 1)
        self.assertEqual(len(detail["leaderboard"]), 1)
        entry = detail["leaderboard"][0]
        self.assertEqual(entry["participant_id"], str(participation.id))
        self.assertEqual(entry["rank"], 1)
        self.assertEqual(detail["user_rank"]["rank"], 1)

    def test_enroll_creates_participation_and_reenroll_returns_code(self):
        create_response = self.client.post(self.enroll_url, {})
        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED, create_response.data)
        participation_id = create_response.data["id"]
        self.assertTrue(ChallengeParticipation.objects.filter(id=participation_id).exists())

        repeat_response = self.client.post(self.enroll_url, {})
        self.assertEqual(repeat_response.status_code, status.HTTP_200_OK)
        self.assertEqual(repeat_response.data["code"], "ALREADY_ENROLLED")

    def test_enroll_rejects_journey_already_linked_elsewhere(self):
        journey = Journey.objects.create(
            owner=self.user,
            title="Epic Trade-Up",
            visibility=JourneyVisibility.PUBLIC,
        )
        ChallengeParticipation.objects.create(
            challenge=self.challenge,
            user=self.user,
            journey=journey,
        )
        other_challenge = Challenge.objects.create(
            title="Weekend Swap Sprint",
            status=ChallengeStatus.ACTIVE,
            start_at=timezone.now(),
            end_at=timezone.now() + timezone.timedelta(days=2),
        )
        other_url = reverse("challenges:challenge-enroll", kwargs={"pk": other_challenge.id})
        response = self.client.post(other_url, {"journey_id": str(journey.id)}, format="json")
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
        self.assertIn("Journey is already linked", str(response.data))

    def test_progress_updates_totals_and_notifies(self):
        journey = Journey.objects.create(
            owner=self.user,
            title="Weekend Challenge",
            visibility=JourneyVisibility.PUBLIC,
        )
        participation = ChallengeParticipation.objects.create(
            challenge=self.challenge,
            user=self.user,
            journey=journey,
        )
        step = JourneyStep.objects.create(journey=journey, sequence=1, notes="Started with a paperclip")

        calls = []

        async def fake_group_send(*args, **kwargs):
            calls.append((args, kwargs))

        with patch("challenges.api.views.get_channel_layer") as mock_layer:
            mock_layer.return_value = SimpleNamespace(group_send=fake_group_send)
            response = self.client.post(
                self.progress_url,
                {
                    "journey_id": str(journey.id),
                    "step_id": str(step.id),
                    "trade_delta_value": "45.50",
                    "notes": "Swapped to a set of vintage pins",
                },
                format="json",
            )

        self.assertEqual(response.status_code, status.HTTP_202_ACCEPTED, response.data)
        participation.refresh_from_db()
        self.assertEqual(participation.total_trade_delta, Decimal("45.50"))
        self.assertEqual(participation.trades_completed, 1)
        self.assertEqual(participation.last_step, step)
        self.assertEqual(len(calls), 1)
        (group_name, message), _ = calls[0]
        self.assertEqual(group_name, f"challenge_{self.challenge.id}")
        self.assertEqual(message["payload"]["rank"], 1)
        self.assertEqual(ChallengeProgress.objects.count(), 1)

    def test_leave_challenge_removes_enrollment(self):
        participation = ChallengeParticipation.objects.create(
            challenge=self.challenge,
            user=self.user,
        )
        response = self.client.delete(self.enroll_url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(ChallengeParticipation.objects.filter(id=participation.id).exists())
