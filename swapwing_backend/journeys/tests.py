import json
import shutil
import tempfile
from io import BytesIO

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.urls import reverse
from PIL import Image
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from journeys.models import (
    Journey,
    JourneyFollower,
    JourneyStatus,
    JourneyStep,
    JourneyStepStatus,
    JourneyVisibility,
)
from listings.models import Listing, ListingCategory

User = get_user_model()


def _create_image_bytes(name="journey.png", size=(512, 512), color=(10, 180, 230)):
    buffer = BytesIO()
    image = Image.new("RGB", size, color)
    image.save(buffer, format="PNG")
    buffer.seek(0)
    return buffer.getvalue()


@override_settings(MEDIA_ROOT=tempfile.mkdtemp(prefix="journeys-tests-"))
class JourneyAPITests(APITestCase):
    @classmethod
    def tearDownClass(cls):  # pragma: no cover - cleanup helper
        super().tearDownClass()
        shutil.rmtree(cls._overridden_settings["MEDIA_ROOT"], ignore_errors=True)

    def setUp(self):
        self.owner = User.objects.create_user(
            email="author@example.com",
            password="TestPass123",
            first_name="Story",
            last_name="Teller",
        )
        self.viewer = User.objects.create_user(
            email="viewer@example.com",
            password="TestPass123",
            first_name="Curious",
            last_name="Follower",
        )
        self.other = User.objects.create_user(
            email="other@example.com",
            password="TestPass123",
            first_name="Other",
            last_name="Trader",
        )

        token = Token.objects.get(user=self.owner)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")

        self.list_url = reverse("journeys:journey-list")
        self.listing = Listing.objects.create(
            owner=self.owner,
            title="Paperclip Starter",
            category=ListingCategory.GOODS,
            description="Tiny but mighty seed listing.",
        )

    def test_create_journey_and_add_step_with_media(self):
        payload = {
            "title": "Paperclip to Laptop",
            "description": "Documenting every swap in the journey.",
            "starting_listing_id": str(self.listing.id),
            "starting_value": "0.50",
            "target_value": "1500.00",
            "tags": ["paperclip", "trade-up"],
            "visibility": JourneyVisibility.PUBLIC,
        }

        response = self.client.post(self.list_url, data=payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        journey_id = response.data["id"]
        journey = Journey.objects.get(id=journey_id)
        self.assertEqual(journey.owner, self.owner)
        self.assertEqual(journey.tags, ["paperclip", "trade-up"])
        self.assertEqual(journey.status, JourneyStatus.DRAFT)

        step_url = reverse("journeys:journey-step-list", kwargs={"journey_pk": journey_id})
        upload = SimpleUploadedFile(
            "step.png", _create_image_bytes(), content_type="image/png"
        )
        step_payload = {
            "notes": "Traded a paperclip for a pen.",
            "from_value": "0.50",
            "to_value": "2.00",
            "media_files": [upload],
            "media_urls": json.dumps(["https://cdn.swapwing.app/pen.jpg"]),
        }

        step_response = self.client.post(step_url, data=step_payload, format="multipart")
        self.assertEqual(step_response.status_code, status.HTTP_201_CREATED, step_response.data)
        step = JourneyStep.objects.get(id=step_response.data["id"])
        self.assertEqual(step.sequence, 1)
        self.assertEqual(step.status, JourneyStepStatus.DRAFT)
        self.assertEqual(step.media.count(), 2)
        uploaded_media = step.media.filter(external_url="").first()
        self.assertTrue(uploaded_media.file.name.startswith(f"journeys/{journey_id}/steps/{step.id}"))

    def test_visibility_and_follow_filters(self):
        public_journey = Journey.objects.create(
            owner=self.other,
            title="Public Journey",
            visibility=JourneyVisibility.PUBLIC,
            status=JourneyStatus.ACTIVE,
        )
        followers_only = Journey.objects.create(
            owner=self.other,
            title="Followers Journey",
            visibility=JourneyVisibility.FOLLOWERS,
            status=JourneyStatus.ACTIVE,
        )
        JourneyFollower.objects.create(journey=followers_only, user=self.owner)
        Journey.objects.create(
            owner=self.other,
            title="Private Journey",
            visibility=JourneyVisibility.PRIVATE,
            status=JourneyStatus.ACTIVE,
        )

        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        returned_titles = {item["title"] for item in response.data}
        self.assertIn(public_journey.title, returned_titles)
        self.assertIn(followers_only.title, returned_titles)
        self.assertNotIn("Private Journey", returned_titles)

        following_response = self.client.get(self.list_url, {"following": "true"})
        self.assertEqual(following_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(following_response.data), 1)
        self.assertEqual(following_response.data[0]["title"], followers_only.title)

    def test_publish_endpoint_marks_steps_active(self):
        journey = Journey.objects.create(
            owner=self.owner,
            title="Draft Journey",
            visibility=JourneyVisibility.PUBLIC,
        )
        JourneyStep.objects.create(journey=journey, sequence=1, notes="Initial step")

        url = reverse("journeys:journey-publish", kwargs={"pk": journey.id})
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        journey.refresh_from_db()
        self.assertEqual(journey.status, JourneyStatus.ACTIVE)
        self.assertIsNotNone(journey.published_at)
        step = journey.steps.first()
        self.assertEqual(step.status, JourneyStepStatus.PUBLISHED)
        self.assertEqual(response.data["steps_updated"], 1)

    def test_follow_and_unfollow_journey(self):
        journey = Journey.objects.create(
            owner=self.other,
            title="Community Build",
            visibility=JourneyVisibility.PUBLIC,
            status=JourneyStatus.ACTIVE,
        )

        url = reverse("journeys:journey-follow", kwargs={"pk": journey.id})
        follow_response = self.client.post(url)
        self.assertEqual(follow_response.status_code, status.HTTP_200_OK)
        self.assertTrue(JourneyFollower.objects.filter(journey=journey, user=self.owner).exists())

        unfollow_response = self.client.delete(url)
        self.assertEqual(unfollow_response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(JourneyFollower.objects.filter(journey=journey, user=self.owner).exists())

    def test_follower_cannot_modify_steps(self):
        journey = Journey.objects.create(
            owner=self.other,
            title="Followers Only",
            visibility=JourneyVisibility.FOLLOWERS,
            status=JourneyStatus.ACTIVE,
        )
        JourneyFollower.objects.create(journey=journey, user=self.owner)

        step_list_url = reverse("journeys:journey-step-list", kwargs={"journey_pk": journey.id})
        upload = SimpleUploadedFile(
            "blocked.png", _create_image_bytes("blocked.png"), content_type="image/png"
        )
        payload = {
            "notes": "Trying to add someone else's step.",
            "media_files": [upload],
        }
        response = self.client.post(step_list_url, data=payload, format="multipart")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

        list_response = self.client.get(step_list_url)
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(list_response.data, [])
