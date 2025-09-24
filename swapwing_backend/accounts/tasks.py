"""Celery tasks for account workflows."""

from celery import shared_task
from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string

from accounts.models import EmailVerificationToken


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def send_email_verification(self, token_id):
    try:
        token = EmailVerificationToken.objects.select_related("user").get(id=token_id)
    except EmailVerificationToken.DoesNotExist:
        return

    user = token.user
    if user.email_verified:
        return

    subject = getattr(
        settings,
        "EMAIL_VERIFICATION_SUBJECT",
        "Verify your SwapWing email",
    )

    context = {
        "first_name": user.first_name or user.email.split("@")[0],
        "code": token.code,
        "verification_url": token.build_verification_url(),
        "expires_in_minutes": getattr(
            settings, "EMAIL_VERIFICATION_TOKEN_TTL_MINUTES", 30
        ),
        "support_email": getattr(settings, "SUPPORT_EMAIL", settings.DEFAULT_FROM_EMAIL),
    }

    text_body = render_to_string("registration/emails/verify.txt", context)
    html_body = render_to_string("registration/emails/verify.html", context)

    message = EmailMultiAlternatives(
        subject=subject,
        body=text_body,
        from_email=settings.DEFAULT_FROM_EMAIL,
        to=[user.email],
    )
    message.attach_alternative(html_body, "text/html")
    message.send()
