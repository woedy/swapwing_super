import json

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.validators import URLValidator
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from listings.models import Listing, ListingMedia

User = get_user_model()


class ListingOwnerSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("user_id", "email", "first_name", "last_name")
        read_only_fields = fields


class ListingMediaSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()
    source = serializers.SerializerMethodField()

    class Meta:
        model = ListingMedia
        fields = ("id", "media_type", "url", "source", "order")
        read_only_fields = fields

    def get_url(self, obj: ListingMedia) -> str | None:
        if obj.external_url:
            return obj.external_url
        if not obj.file:
            return None
        request = self.context.get("request")
        url = obj.file.url
        if request:
            return request.build_absolute_uri(url)
        return url

    def get_source(self, obj: ListingMedia) -> str:
        return "external" if obj.external_url else "upload"


class ListingSerializer(serializers.ModelSerializer):
    owner = ListingOwnerSerializer(read_only=True)
    media = ListingMediaSerializer(many=True, read_only=True)
    tags = serializers.JSONField(required=False)

    media_files = serializers.ListField(
        child=serializers.FileField(),
        write_only=True,
        required=False,
        allow_empty=True,
    )
    media_urls = serializers.JSONField(required=False)
    remove_media_ids = serializers.ListField(
        child=serializers.UUIDField(),
        write_only=True,
        required=False,
        allow_empty=True,
    )

    class Meta:
        model = Listing
        fields = (
            "id",
            "owner",
            "title",
            "description",
            "category",
            "tags",
            "estimated_value",
            "is_trade_up_eligible",
            "location",
            "status",
            "media",
            "media_files",
            "media_urls",
            "remove_media_ids",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "owner", "media", "created_at", "updated_at")

    def _normalize_tags(self, value) -> list[str]:
        if value in (None, "", []):
            return []
        if isinstance(value, str):
            try:
                value = json.loads(value)
            except json.JSONDecodeError as exc:
                raise serializers.ValidationError(
                    _("Tags must be provided as a JSON array of strings."), code="invalid"
                ) from exc
        if not isinstance(value, list):
            raise serializers.ValidationError(
                _("Tags must be provided as a list of strings."), code="invalid"
            )
        cleaned = []
        for tag in value:
            if not isinstance(tag, str):
                raise serializers.ValidationError(
                    _("Each tag must be a string."), code="invalid"
                )
            cleaned_tag = tag.strip()
            if cleaned_tag:
                cleaned.append(cleaned_tag)
        return cleaned

    def validate_tags(self, value):
        return self._normalize_tags(value)

    def validate_media_urls(self, value):
        if value in (None, "", []):
            return []
        if isinstance(value, str):
            try:
                value = json.loads(value)
            except json.JSONDecodeError as exc:
                raise serializers.ValidationError(
                    _("media_urls must be a JSON array of URLs."), code="invalid"
                ) from exc
        if not isinstance(value, list):
            raise serializers.ValidationError(
                _("media_urls must be provided as a list of URLs."), code="invalid"
            )
        validator = URLValidator()
        cleaned = []
        for url in value:
            if not isinstance(url, str):
                raise serializers.ValidationError(
                    _("Each media URL must be a string."), code="invalid"
                )
            trimmed = url.strip()
            try:
                validator(trimmed)
            except DjangoValidationError as exc:
                raise serializers.ValidationError(str(exc)) from exc
            cleaned.append(trimmed)
        return cleaned

    def validate(self, attrs):
        media_files = attrs.get("media_files")
        media_urls = attrs.get("media_urls")
        if media_files is None and media_urls is None:
            return attrs
        files = media_files or []
        urls = media_urls or []
        if len(files) + len(urls) > 10:
            raise serializers.ValidationError(
                {"media": _("A maximum of 10 media items can be attached to a listing at once.")}
            )
        return attrs

    def create(self, validated_data):
        media_files = validated_data.pop("media_files", [])
        media_urls = validated_data.pop("media_urls", [])
        owner = validated_data.pop("owner", self.context["request"].user)

        listing = Listing.objects.create(owner=owner, **validated_data)
        self._create_media(listing, media_files, media_urls)
        return listing

    def update(self, instance: Listing, validated_data):
        media_files = validated_data.pop("media_files", [])
        media_urls = validated_data.pop("media_urls", [])
        remove_media_ids = validated_data.pop("remove_media_ids", [])

        validated_data.pop("owner", None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if remove_media_ids:
            instance.media.filter(id__in=remove_media_ids).delete()

        self._create_media(instance, media_files, media_urls)
        instance.refresh_from_db()
        return instance

    def _create_media(self, listing: Listing, media_files, media_urls):
        order_start = listing.media.count()
        for index, file_obj in enumerate(media_files or [], start=1):
            media = ListingMedia(listing=listing, file=file_obj, order=order_start + index)
            media.full_clean()
            media.save()
        for index, url in enumerate(media_urls or [], start=1):
            media = ListingMedia(
                listing=listing,
                external_url=url,
                order=order_start + len(media_files or []) + index,
            )
            media.full_clean()
            media.save()

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data.pop("media_files", None)
        data.pop("media_urls", None)
        data.pop("remove_media_ids", None)
        return data
