from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core import mail
from django.test import override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import EmailVerificationToken
from accounts.services import issue_email_verification_token

User = get_user_model()


@override_settings(
    EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend",
    CELERY_TASK_ALWAYS_EAGER=True,
    CELERY_TASK_EAGER_PROPAGATES=True,
)
class EmailVerificationFlowTests(APITestCase):
    def test_user_registration_creates_inactive_user_and_sends_email(self):
        response = self.client.post(
            reverse("accounts_api:user_registration_view"),
            {
                "email": "test@example.com",
                "username": "tester",
                "first_name": "Test",
                "last_name": "User",
                "password": "SwapWing!123",
                "password2": "SwapWing!123",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(email="test@example.com")
        self.assertFalse(user.is_active)
        self.assertFalse(user.email_verified)
        self.assertEqual(EmailVerificationToken.objects.filter(user=user).count(), 1)
        self.assertEqual(len(mail.outbox), 1)

    def test_verify_user_email_success(self):
        user = User.objects.create_user(
            email="verify@example.com",
            password="SwapWing!123",
            first_name="Verify",
            last_name="Me",
            is_active=False,
        )
        token = issue_email_verification_token(user)

        response = self.client.post(
            reverse("accounts_api:verify_user_email"),
            {"email": user.email, "email_token": token.code},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        user.refresh_from_db()
        token.refresh_from_db()
        self.assertTrue(user.email_verified)
        self.assertTrue(user.is_active)
        self.assertIsNotNone(token.consumed_at)

    def test_verify_user_email_rejects_expired_token(self):
        user = User.objects.create_user(
            email="expired@example.com",
            password="SwapWing!123",
            first_name="Expired",
            last_name="Token",
            is_active=False,
        )
        token = issue_email_verification_token(user)
        EmailVerificationToken.objects.filter(pk=token.pk).update(
            expires_at=timezone.now() - timedelta(minutes=1)
        )

        response = self.client.post(
            reverse("accounts_api:verify_user_email"),
            {"email": user.email, "email_token": token.code},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        user.refresh_from_db()
        self.assertFalse(user.email_verified)

    def test_resend_email_verification_creates_new_token(self):
        user = User.objects.create_user(
            email="resend@example.com",
            password="SwapWing!123",
            first_name="Re",
            last_name="Send",
            is_active=False,
        )
        original = issue_email_verification_token(user)
        EmailVerificationToken.objects.filter(pk=original.pk).update(
            created_at=timezone.now() - timedelta(minutes=5)
        )
        mail.outbox = []

        response = self.client.post(
            reverse("accounts_api:resend_email_verification"),
            {"email": user.email},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_202_ACCEPTED)
        user_tokens = EmailVerificationToken.objects.filter(user=user)
        self.assertEqual(user_tokens.filter(consumed_at__isnull=True).count(), 1)
        self.assertEqual(len(mail.outbox), 1)
