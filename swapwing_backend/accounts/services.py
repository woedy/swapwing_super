"""Domain services for account workflows."""

import secrets
import string
from datetime import timedelta

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from accounts.models import EmailVerificationToken


def _generate_unique_code():
    """Generate a numeric code that is not active for any user."""
    length = getattr(settings, "EMAIL_VERIFICATION_CODE_LENGTH", 6)
    alphabet = string.digits
    now = timezone.now()
    for _ in range(10):
        code = "".join(secrets.choice(alphabet) for _ in range(length))
        exists = EmailVerificationToken.objects.filter(
            code=code,
            consumed_at__isnull=True,
            expires_at__gt=now,
        ).exists()
        if not exists:
            return code
    return "".join(secrets.choice(alphabet) for _ in range(length))


@transaction.atomic
def issue_email_verification_token(user):
    """Create a fresh verification token for a user, invalidating previous ones."""
    now = timezone.now()
    EmailVerificationToken.objects.filter(
        user=user,
        consumed_at__isnull=True,
    ).update(consumed_at=now)

    expires_at = now + timedelta(
        minutes=getattr(settings, "EMAIL_VERIFICATION_TOKEN_TTL_MINUTES", 30)
    )

    token = EmailVerificationToken.objects.create(
        user=user,
        code=_generate_unique_code(),
        token=secrets.token_urlsafe(32),
        expires_at=expires_at,
    )
    return token


def mark_user_email_verified(user, *, save=True):
    user.email_verified = True
    user.is_active = True
    user.email_token = None
    if save:
        user.save(update_fields=["email_verified", "is_active", "email_token"])
    return user
