import json
import uuid
from decimal import Decimal
from pathlib import Path

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator
from django.db import models


class ListingCategory(models.TextChoices):
    GOODS = "goods", "Goods"
    SERVICES = "services", "Services"
    DIGITAL = "digital", "Digital"
    AUTOMOTIVE = "automotive", "Automotive"
    ELECTRONICS = "electronics", "Electronics"
    FASHION = "fashion", "Fashion"
    HOME = "home", "Home"
    SPORTS = "sports", "Sports"


class ListingStatus(models.TextChoices):
    ACTIVE = "active", "Active"
    TRADED = "traded", "Traded"
    EXPIRED = "expired", "Expired"
    DELETED = "deleted", "Deleted"


class Listing(models.Model):
    """A marketplace listing for a good or service."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="listings",
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    category = models.CharField(
        max_length=32,
        choices=ListingCategory.choices,
    )
    tags = models.JSONField(default=list, blank=True)
    estimated_value = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(Decimal("0"))],
    )
    is_trade_up_eligible = models.BooleanField(default=False)
    location = models.CharField(max_length=255, blank=True)
    status = models.CharField(
        max_length=32,
        choices=ListingStatus.choices,
        default=ListingStatus.ACTIVE,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["category"]),
            models.Index(fields=["is_trade_up_eligible"]),
        ]

    def clean(self):
        super().clean()
        if isinstance(self.tags, str):
            try:
                self.tags = json.loads(self.tags)
            except json.JSONDecodeError as exc:
                raise ValidationError({"tags": "Tags must be a list of strings."}) from exc
        if not isinstance(self.tags, list):
            raise ValidationError({"tags": "Tags must be a list of strings."})
        if any(not isinstance(tag, str) for tag in self.tags):
            raise ValidationError({"tags": "Each tag must be a string."})

    def __str__(self) -> str:
        return f"{self.title} ({self.category})"


def listing_media_upload_to(instance: "ListingMedia", filename: str) -> str:
    ext = Path(filename or "").suffix or ".bin"
    return f"listings/{instance.listing_id}/media/{uuid.uuid4()}{ext}"


class ListingMedia(models.Model):
    class MediaType(models.TextChoices):
        IMAGE = "image", "Image"
        VIDEO = "video", "Video"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing = models.ForeignKey(
        Listing,
        on_delete=models.CASCADE,
        related_name="media",
    )
    media_type = models.CharField(
        max_length=16,
        choices=MediaType.choices,
        default=MediaType.IMAGE,
    )
    file = models.FileField(upload_to=listing_media_upload_to, blank=True)
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

    def __str__(self) -> str:
        return f"Media {self.id} for listing {self.listing_id}"
