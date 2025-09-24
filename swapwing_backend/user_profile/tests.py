from __future__ import annotations

import json
from io import BytesIO

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.urls import reverse
from PIL import Image
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase


class ProfileDocumentTests(APITestCase):
    def setUp(self):
        User = get_user_model()
        self.user = User.objects.create_user(
            email="trader@example.com",
            password="StrongPass123",
            first_name="Trade",
            last_name="Rex",
        )
        token = Token.objects.get(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {token.key}")
        self.url = reverse("user_profile:profile_me")

    def _create_image(self, name="test.png", size=(512, 512), color=(200, 50, 50), image_format="PNG", save_kwargs=None):
        buffer = BytesIO()
        image = Image.new("RGB", size, color)
        image.save(buffer, format=image_format, **(save_kwargs or {}))
        buffer.seek(0)
        content_type = f"image/{image_format.lower()}"
        return SimpleUploadedFile(name, buffer.read(), content_type=content_type)

    def test_update_profile_with_valid_documents(self):
        avatar = self._create_image(name="avatar.png", size=(512, 512))
        id_document = self._create_image(name="id-card.png", size=(720, 720))

        payload = {
            "phone": "+1234567890",
            "about_me": "I love trading up electronics.",
            "country": "USA",
            "id_type": "Passport",
            "id_number": "A1234567",
            "photo": avatar,
            "id_card_image": id_document,
            "social_links": json.dumps([
                {"name": "Twitter", "link": "https://twitter.com/swapwing", "active": True}
            ]),
        }

        response = self.client.patch(self.url, data=payload, format="multipart")

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["profile_complete"])
        self.assertEqual(len(response.data["social_links"]), 1)
        self.user.refresh_from_db()

        personal_info = self.user.user_personal_info
        self.assertTrue(personal_info.photo.name.startswith(f"users/{self.user.user_id}/avatars/"))
        self.assertTrue(personal_info.id_card_image.name.startswith(f"users/{self.user.user_id}/identity/"))

    def test_rejects_invalid_id_document_extension(self):
        invalid_file = SimpleUploadedFile(
            "identity.txt",
            b"not-a-valid-document",
            content_type="text/plain",
        )

        payload = {
            "id_card_image": invalid_file,
            "id_type": "Passport",
            "id_number": "A1234567",
        }

        response = self.client.patch(self.url, data=payload, format="multipart")

        self.assertEqual(response.status_code, 400)
        self.assertIn("id_card_image", response.data)

    @override_settings(PROFILE_AVATAR_MAX_SIZE_MB=0.05)
    def test_rejects_avatar_exceeding_size_limit(self):
        oversized_avatar = self._create_image(
            name="huge.jpg",
            size=(2048, 2048),
            image_format="JPEG",
            save_kwargs={"quality": 100},
        )

        response = self.client.patch(
            self.url,
            data={"photo": oversized_avatar},
            format="multipart",
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("photo", response.data)
