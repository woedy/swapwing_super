"""Models powering trade journey authoring and storytelling."""

from __future__ import annotations

import json
import uuid
from decimal import Decimal
from pathlib import Path

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator
from django.db import models
from django.utils import timezone

from listings.models import Listing


class JourneyVisibility(models.TextChoices):
    PUBLIC = "public", "Public"
    FOLLOWERS = "followers", "Followers"
    PRIVATE = "private", "Private"


class JourneyStatus(models.TextChoices):
    DRAFT = "draft", "Draft"
    ACTIVE = "active", "Active"
    COMPLETED = "completed", "Completed"


class Journey(models.Model):
    """A trader's narrative that documents progressive trade-up steps."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="journeys",
        on_delete=models.CASCADE,
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    starting_listing = models.ForeignKey(
        Listing,
        null=True,
        blank=True,
        related_name="journey_starts",
        on_delete=models.SET_NULL,
    )
    starting_value = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
    )
    target_value = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
    )
    tags = models.JSONField(default=list, blank=True)
    visibility = models.CharField(
        max_length=32,
        choices=JourneyVisibility.choices,
        default=JourneyVisibility.PUBLIC,
    )
    status = models.CharField(
        max_length=32,
        choices=JourneyStatus.choices,
        default=JourneyStatus.DRAFT,
    )
    published_at = models.DateTimeField(null=True, blank=True)
    followers = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        through="JourneyFollower",
        related_name="followed_journeys",
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["visibility"]),
            models.Index(fields=["owner"]),
        ]

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"{self.title} ({self.status})"

    def clean(self):
        super().clean()
        if isinstance(self.tags, str):
            try:
                self.tags = json.loads(self.tags)
            except json.JSONDecodeError as exc:  # pragma: no cover - validation branch
                raise ValidationError({"tags": "Tags must be a list of strings."}) from exc
        if not isinstance(self.tags, list):
            raise ValidationError({"tags": "Tags must be a list of strings."})
        if any(not isinstance(tag, str) for tag in self.tags):
            raise ValidationError({"tags": "Each tag must be a string."})

    def mark_published(self):
        """Transition the journey to an active state if still in draft."""

        if self.status == JourneyStatus.DRAFT:
            self.status = JourneyStatus.ACTIVE
            self.published_at = timezone.now()
            self.save(update_fields=["status", "published_at", "updated_at"])


class JourneyFollower(models.Model):
    """Tracks a user following a given journey."""

    journey = models.ForeignKey(
        Journey,
        related_name="follower_links",
        on_delete=models.CASCADE,
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="journey_follow_links",
        on_delete=models.CASCADE,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("journey", "user")
        ordering = ["-created_at"]

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"{self.user_id} -> {self.journey_id}"


class JourneyStepStatus(models.TextChoices):
    DRAFT = "draft", "Draft"
    PUBLISHED = "published", "Published"


class JourneyStep(models.Model):
    """A discrete trade action that advances a journey."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    journey = models.ForeignKey(
        Journey,
        related_name="steps",
        on_delete=models.CASCADE,
    )
    sequence = models.PositiveIntegerField()
    from_listing = models.ForeignKey(
        Listing,
        null=True,
        blank=True,
        related_name="journey_steps_from",
        on_delete=models.SET_NULL,
    )
    to_listing = models.ForeignKey(
        Listing,
        null=True,
        blank=True,
        related_name="journey_steps_to",
        on_delete=models.SET_NULL,
    )
    from_value = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
    )
    to_value = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
    )
    notes = models.TextField(blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(
        max_length=16,
        choices=JourneyStepStatus.choices,
        default=JourneyStepStatus.DRAFT,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["sequence", "created_at"]
        unique_together = ("journey", "sequence")

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"Step {self.sequence} of journey {self.journey_id}"


def journey_step_media_upload_to(instance: "JourneyStepMedia", filename: str) -> str:
    ext = Path(filename or "").suffix or ".bin"
    return f"journeys/{instance.step.journey_id}/steps/{instance.step_id}/{uuid.uuid4()}{ext}"


class JourneyStepMedia(models.Model):
    class MediaType(models.TextChoices):
        IMAGE = "image", "Image"
        VIDEO = "video", "Video"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    step = models.ForeignKey(
        JourneyStep,
        related_name="media",
        on_delete=models.CASCADE,
    )
    media_type = models.CharField(
        max_length=16,
        choices=MediaType.choices,
        default=MediaType.IMAGE,
    )
    file = models.FileField(
        upload_to=journey_step_media_upload_to,
        blank=True,
        max_length=500,
    )
    external_url = models.URLField(blank=True)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order", "created_at"]

    def clean(self):
        super().clean()
        if not self.file and not self.external_url:
            raise ValidationError("Provide an uploaded file or external_url for media.")
        if self.file and self.external_url:
            raise ValidationError("Provide either an uploaded file or an external_url, not both.")

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"Media {self.id} for step {self.step_id}"
