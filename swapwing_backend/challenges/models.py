"""Data models for SwapWing challenge enrollment and leaderboards."""

from __future__ import annotations

import uuid
from decimal import Decimal

from django.conf import settings
from django.core.validators import MinValueValidator
from django.db import models
from django.db.models import Q

from journeys.models import Journey, JourneyStep


class ChallengeStatus(models.TextChoices):
    UPCOMING = "upcoming", "Upcoming"
    ACTIVE = "active", "Active"
    COMPLETED = "completed", "Completed"


class ChallengeCategory(models.TextChoices):
    GENERAL = "general", "General"
    SUSTAINABILITY = "sustainability", "Sustainability"
    COMMUNITY = "community", "Community"
    TECHNOLOGY = "technology", "Technology"
    CREATORS = "creators", "Creators"


class Challenge(models.Model):
    """A themed community challenge with leaderboard tracking."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    cta_copy = models.CharField(max_length=255, blank=True)
    cover_image_url = models.URLField(blank=True)
    banner_image_url = models.URLField(blank=True)
    status = models.CharField(
        max_length=32,
        choices=ChallengeStatus.choices,
        default=ChallengeStatus.UPCOMING,
    )
    category = models.CharField(
        max_length=64,
        choices=ChallengeCategory.choices,
        blank=True,
    )
    start_at = models.DateTimeField(null=True, blank=True)
    end_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-start_at", "title"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["category"]),
            models.Index(fields=["start_at"]),
        ]

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"{self.title} ({self.status})"


class ChallengeMilestone(models.Model):
    """Target thresholds that encourage steady progress during a challenge."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    challenge = models.ForeignKey(
        Challenge,
        related_name="milestones",
        on_delete=models.CASCADE,
    )
    label = models.CharField(max_length=255)
    target_value = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))],
    )
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["order", "target_value"]
        unique_together = ("challenge", "label")

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"{self.label} @ {self.target_value}"


class ChallengePrize(models.Model):
    """Tiered rewards for leaderboard standings."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    challenge = models.ForeignKey(
        Challenge,
        related_name="prizes",
        on_delete=models.CASCADE,
    )
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    rank_start = models.PositiveIntegerField()
    rank_end = models.PositiveIntegerField(null=True, blank=True)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["order", "rank_start"]
        unique_together = ("challenge", "name")

    def __str__(self) -> str:  # pragma: no cover - debug helper
        if self.rank_end and self.rank_end != self.rank_start:
            return f"{self.name} (ranks {self.rank_start}-{self.rank_end})"
        return f"{self.name} (rank {self.rank_start})"


class ChallengeParticipation(models.Model):
    """A trader's enrollment in a challenge with aggregated progress."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    challenge = models.ForeignKey(
        Challenge,
        related_name="participations",
        on_delete=models.CASCADE,
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        related_name="challenge_participations",
        on_delete=models.CASCADE,
    )
    journey = models.ForeignKey(
        Journey,
        related_name="challenge_participations",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    total_trade_delta = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0"),
        validators=[MinValueValidator(Decimal("0"))],
    )
    trades_completed = models.PositiveIntegerField(default=0)
    last_progress_at = models.DateTimeField(null=True, blank=True)
    last_step = models.ForeignKey(
        JourneyStep,
        null=True,
        blank=True,
        related_name="challenge_participations_last",
        on_delete=models.SET_NULL,
    )
    joined_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["challenge", "-total_trade_delta", "joined_at"]
        unique_together = ("challenge", "user")
        constraints = [
            models.UniqueConstraint(
                fields=["journey"],
                condition=Q(journey__isnull=False),
                name="unique_challenge_participation_journey",
            )
        ]

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"{self.user_id} in {self.challenge_id}"


class ChallengeProgress(models.Model):
    """Snapshot of incremental value gained within a challenge."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    participation = models.ForeignKey(
        ChallengeParticipation,
        related_name="progress_entries",
        on_delete=models.CASCADE,
    )
    journey_step = models.ForeignKey(
        JourneyStep,
        null=True,
        blank=True,
        related_name="challenge_progress_entries",
        on_delete=models.SET_NULL,
    )
    trade_delta_value = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal("0"))],
    )
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:  # pragma: no cover - debug helper
        return f"Progress {self.trade_delta_value} for {self.participation_id}"
