from __future__ import annotations

import json
import shutil
import tempfile
from io import BytesIO

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.urls import reverse
from PIL import Image
from rest_framework.authtoken.models import Token
from rest_framework import status
from rest_framework.test import APITestCase

from listings.models import Listing, ListingMedia, ListingCategory

User = get_user_model()


def _create_image_file(name="listing.png", size=(640, 480), color=(120, 40, 200)):
    buffer = BytesIO()
    image = Image.new("RGB", size, color)
    image.save(buffer, format="PNG")
    buffer.seek(0)
    return buffer.getvalue()


@override_settings(MEDIA_ROOT=tempfile.mkdtemp(prefix="listings-tests-"))
class ListingAPITests(APITestCase):
    @classmethod
    def tearDownClass(cls):  # pragma: no cover - cleanup helper
        super().tearDownClass()
        shutil.rmtree(cls._overridden_settings["MEDIA_ROOT"], ignore_errors=True)

    def setUp(self):
        self.user = User.objects.create_user(
            email="owner@example.com",
            password="StrongPass123",
            first_name="Owner",
            last_name="User",
        )
        self.other_user = User.objects.create_user(
            email="other@example.com",
            password="StrongPass123",
            first_name="Other",
            last_name="Trader",
        )
        token = Token.objects.get(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")
        self.list_url = reverse("listings:listing-list")

    def test_create_listing_with_uploaded_media_and_urls(self):
        image_bytes = _create_image_file()
        upload = SimpleUploadedFile("camera.png", image_bytes, content_type="image/png")

        payload = {
            "title": "Vintage Camera",
            "description": "Classic instant camera in excellent condition.",
            "category": ListingCategory.ELECTRONICS,
            "estimated_value": "180.00",
            "is_trade_up_eligible": True,
            "tags": json.dumps(["camera", "vintage"]),
            "media_files": [upload],
            "media_urls": json.dumps(["https://cdn.swapwing.app/camera.jpg"]),
        }

        response = self.client.post(self.list_url, data=payload, format="multipart")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        listing = Listing.objects.get(id=response.data["id"])
        self.assertEqual(listing.owner, self.user)
        self.assertEqual(listing.tags, ["camera", "vintage"])
        self.assertEqual(listing.media.count(), 2)

        uploaded_media = listing.media.filter(external_url="").first()
        self.assertTrue(uploaded_media.file.name.startswith(f"listings/{listing.id}/media/"))

        external_media = listing.media.exclude(external_url="").first()
        self.assertEqual(external_media.external_url, "https://cdn.swapwing.app/camera.jpg")

    def test_filter_listings_by_category_and_search(self):
        Listing.objects.create(
            owner=self.user,
            title="Vintage Camera",
            description="Classic instant camera",
            category=ListingCategory.ELECTRONICS,
            tags=["camera", "vintage"],
            estimated_value="150.00",
            is_trade_up_eligible=True,
            location="San Francisco",
        )
        Listing.objects.create(
            owner=self.user,
            title="Yoga Classes",
            description="Ten session wellness pack",
            category=ListingCategory.SERVICES,
            tags=["wellness"],
            estimated_value="120.00",
            location="San Jose",
        )

        response = self.client.get(
            self.list_url,
            {"category": ListingCategory.ELECTRONICS, "search": "vintage"},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["title"], "Vintage Camera")

    def test_only_owner_can_update_listing(self):
        listing = Listing.objects.create(
            owner=self.user,
            title="Vintage Camera",
            description="Classic instant camera",
            category=ListingCategory.ELECTRONICS,
        )

        token = Token.objects.get(user=self.other_user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")
        url = reverse("listings:listing-detail", args=[listing.id])

        response = self.client.patch(url, {"title": "Hacked"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_update_listing_add_and_remove_media(self):
        listing = Listing.objects.create(
            owner=self.user,
            title="Vintage Camera",
            description="Classic instant camera",
            category=ListingCategory.ELECTRONICS,
        )
        ListingMedia.objects.create(
            listing=listing,
            external_url="https://cdn.swapwing.app/old-camera.jpg",
            order=1,
        )

        self.client.credentials(HTTP_AUTHORIZATION=f"Token {Token.objects.get(user=self.user).key}")

        new_file = SimpleUploadedFile("new.png", _create_image_file("new.png"), content_type="image/png")

        url = reverse("listings:listing-detail", args=[listing.id])
        payload = {
            "title": "Updated Vintage Camera",
            "remove_media_ids": [str(listing.media.first().id)],
            "media_files": [new_file],
        }

        response = self.client.patch(url, data=payload, format="multipart")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        listing.refresh_from_db()
        self.assertEqual(listing.title, "Updated Vintage Camera")
        self.assertEqual(listing.media.count(), 1)
        self.assertEqual(listing.media.first().external_url, "")

    def test_delete_listing(self):
        listing = Listing.objects.create(
            owner=self.user,
            title="Vintage Camera",
            description="Classic instant camera",
            category=ListingCategory.ELECTRONICS,
        )
        url = reverse("listings:listing-detail", args=[listing.id])
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Listing.objects.filter(id=listing.id).exists())
