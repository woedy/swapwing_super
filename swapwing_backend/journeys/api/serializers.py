import json

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.validators import URLValidator
from django.db.models import Max
from rest_framework import serializers

from journeys.models import (
    Journey,
    JourneyStatus,
    JourneyStep,
    JourneyStepMedia,
    JourneyStepStatus,
)
from listings.models import Listing

User = get_user_model()


class JourneyOwnerSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("user_id", "email", "first_name", "last_name")
        read_only_fields = fields


class JourneyFollowerSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("user_id", "first_name", "last_name")
        read_only_fields = fields


class JourneyStepMediaSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()
    source = serializers.SerializerMethodField()

    class Meta:
        model = JourneyStepMedia
        fields = ("id", "media_type", "url", "source", "order")
        read_only_fields = fields

    def get_url(self, obj: JourneyStepMedia) -> str | None:
        if obj.external_url:
            return obj.external_url
        if not obj.file:
            return None
        request = self.context.get("request")
        url = obj.file.url
        if request:
            return request.build_absolute_uri(url)
        return url

    def get_source(self, obj: JourneyStepMedia) -> str:
        return "external" if obj.external_url else "upload"


class JourneyStepSerializer(serializers.ModelSerializer):
    journey_id = serializers.UUIDField(source="journey.id", read_only=True)
    from_listing_id = serializers.PrimaryKeyRelatedField(
        queryset=Listing.objects.all(),
        source="from_listing",
        required=False,
        allow_null=True,
    )
    to_listing_id = serializers.PrimaryKeyRelatedField(
        queryset=Listing.objects.all(),
        source="to_listing",
        required=False,
        allow_null=True,
    )
    media = JourneyStepMediaSerializer(many=True, read_only=True)
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
        model = JourneyStep
        fields = (
            "id",
            "journey_id",
            "sequence",
            "status",
            "from_listing_id",
            "to_listing_id",
            "from_value",
            "to_value",
            "notes",
            "completed_at",
            "media",
            "media_files",
            "media_urls",
            "remove_media_ids",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "journey_id", "created_at", "updated_at")
        extra_kwargs = {
            "sequence": {"required": False},
            "status": {"required": False},
        }

    def _normalize_urls(self, value):
        if value in (None, "", []):
            return []
        if isinstance(value, str):
            try:
                value = json.loads(value)
            except json.JSONDecodeError as exc:
                raise serializers.ValidationError("media_urls must be a JSON array of URLs.") from exc
        if not isinstance(value, list):
            raise serializers.ValidationError("media_urls must be provided as a list of URLs.")
        validator = URLValidator()
        cleaned = []
        for url in value:
            if not isinstance(url, str):
                raise serializers.ValidationError("Each media URL must be a string.")
            trimmed = url.strip()
            try:
                validator(trimmed)
            except DjangoValidationError as exc:
                raise serializers.ValidationError(str(exc)) from exc
            cleaned.append(trimmed)
        return cleaned

    def validate_media_urls(self, value):
        return self._normalize_urls(value)

    def validate(self, attrs):
        media_files = attrs.get("media_files")
        media_urls = attrs.get("media_urls")
        if media_files is None and media_urls is None:
            return attrs
        files = media_files or []
        urls = media_urls or []
        if len(files) + len(urls) > 10:
            raise serializers.ValidationError(
                {"media": "A maximum of 10 media items can be attached to a step at once."}
            )
        return attrs

    def validate_status(self, value):
        if not self.instance:
            return value
        transitions = {
            JourneyStepStatus.DRAFT: {JourneyStepStatus.DRAFT, JourneyStepStatus.PUBLISHED},
            JourneyStepStatus.PUBLISHED: {JourneyStepStatus.PUBLISHED},
        }
        allowed = transitions.get(self.instance.status, {self.instance.status})
        if value not in allowed:
            raise serializers.ValidationError("Invalid status transition for step.")
        return value

    def create(self, validated_data):
        media_files = validated_data.pop("media_files", [])
        media_urls = validated_data.pop("media_urls", [])
        journey = validated_data["journey"]
        if "sequence" not in validated_data:
            next_sequence = (journey.steps.aggregate(Max("sequence"))["sequence__max"] or 0) + 1
            validated_data["sequence"] = next_sequence
        step = JourneyStep.objects.create(**validated_data)
        self._create_media(step, media_files, media_urls)
        return step

    def update(self, instance: JourneyStep, validated_data):
        media_files = validated_data.pop("media_files", [])
        media_urls = validated_data.pop("media_urls", [])
        remove_media_ids = validated_data.pop("remove_media_ids", [])

        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if remove_media_ids:
            instance.media.filter(id__in=remove_media_ids).delete()

        self._create_media(instance, media_files, media_urls)
        instance.refresh_from_db()
        return instance

    def _create_media(self, step: JourneyStep, media_files, media_urls):
        order_start = step.media.count()
        for index, file_obj in enumerate(media_files or [], start=1):
            media = JourneyStepMedia(step=step, file=file_obj, order=order_start + index)
            media.full_clean()
            media.save()
        for index, url in enumerate(media_urls or [], start=1):
            media = JourneyStepMedia(
                step=step,
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


class JourneySerializer(serializers.ModelSerializer):
    owner = JourneyOwnerSerializer(read_only=True)
    steps = JourneyStepSerializer(many=True, read_only=True)
    tags = serializers.JSONField(required=False)
    starting_listing_id = serializers.PrimaryKeyRelatedField(
        queryset=Listing.objects.all(),
        source="starting_listing",
        required=False,
        allow_null=True,
    )
    followers_count = serializers.SerializerMethodField()
    is_following = serializers.SerializerMethodField()
    sample_followers = serializers.SerializerMethodField()
    next_steps_hint = serializers.SerializerMethodField()

    class Meta:
        model = Journey
        fields = (
            "id",
            "owner",
            "title",
            "description",
            "starting_listing_id",
            "starting_value",
            "target_value",
            "tags",
            "visibility",
            "status",
            "published_at",
            "followers_count",
            "is_following",
            "sample_followers",
            "next_steps_hint",
            "steps",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "owner", "followers_count", "is_following", "sample_followers", "next_steps_hint", "steps", "published_at", "created_at", "updated_at")

    def _normalize_tags(self, value):
        if value in (None, "", []):
            return []
        if isinstance(value, str):
            try:
                value = json.loads(value)
            except json.JSONDecodeError as exc:
                raise serializers.ValidationError("Tags must be provided as a JSON array of strings.") from exc
        if not isinstance(value, list):
            raise serializers.ValidationError("Tags must be provided as a list of strings.")
        cleaned = []
        for tag in value:
            if not isinstance(tag, str):
                raise serializers.ValidationError("Each tag must be a string.")
            cleaned_tag = tag.strip()
            if cleaned_tag:
                cleaned.append(cleaned_tag)
        return cleaned

    def validate_tags(self, value):
        return self._normalize_tags(value)

    def validate_status(self, value):
        if not self.instance:
            return value
        transitions = {
            JourneyStatus.DRAFT: {JourneyStatus.DRAFT, JourneyStatus.ACTIVE},
            JourneyStatus.ACTIVE: {JourneyStatus.ACTIVE, JourneyStatus.COMPLETED},
            JourneyStatus.COMPLETED: {JourneyStatus.COMPLETED},
        }
        allowed = transitions.get(self.instance.status, {self.instance.status})
        if value not in allowed:
            raise serializers.ValidationError("Invalid status transition for journey.")
        return value

    def create(self, validated_data):
        owner = validated_data.pop("owner", self.context["request"].user)
        return Journey.objects.create(owner=owner, **validated_data)

    def update(self, instance: Journey, validated_data):
        original_status = instance.status
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if (
            original_status == JourneyStatus.DRAFT
            and instance.status == JourneyStatus.ACTIVE
            and not instance.published_at
        ):
            instance.published_at = instance.updated_at
            instance.save(update_fields=["published_at", "updated_at"])
        return instance

    def get_followers_count(self, obj: Journey) -> int:
        return obj.followers.count()

    def get_is_following(self, obj: Journey) -> bool:
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if not user or not user.is_authenticated:
            return False
        if obj.owner_id == user.id:
            return True
        return obj.followers.filter(id=user.id).exists()

    def get_sample_followers(self, obj: Journey):
        followers = obj.followers.all()[:10]
        serializer = JourneyFollowerSerializer(followers, many=True, context=self.context)
        return serializer.data

    def get_next_steps_hint(self, obj: Journey) -> str:
        if obj.status == JourneyStatus.COMPLETED:
            return "Celebrate your accomplishment and share the final story with your followers."
        if obj.status == JourneyStatus.ACTIVE:
            return "Keep documenting each trade-up step so the community can follow along."
        return "Publish your first step to move this journey from draft into the spotlight."

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if not self.context.get("include_steps"):
            data.pop("steps", None)
        return data
