from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

from user_profile.models import PersonalInfo, SocialMedia, SOCIAL_MEDIA_CHOICES

User = get_user_model()


class SocialLinkSerializer(serializers.ModelSerializer):
    class Meta:
        model = SocialMedia
        fields = ("id", "name", "link", "active")
        read_only_fields = ("id",)


class PersonalInfoSerializer(serializers.ModelSerializer):
    user_id = serializers.CharField(source="user.user_id", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    first_name = serializers.CharField(source="user.first_name", read_only=True)
    last_name = serializers.CharField(source="user.last_name", read_only=True)
    photo_url = serializers.SerializerMethodField()
    id_card_document_url = serializers.SerializerMethodField()
    social_links = SocialLinkSerializer(source="user.user_social_medias", many=True, read_only=True)

    class Meta:
        model = PersonalInfo
        fields = (
            "user_id",
            "email",
            "first_name",
            "last_name",
            "gender",
            "phone",
            "about_me",
            "country",
            "id_type",
            "id_number",
            "profile_complete",
            "verified",
            "photo_url",
            "id_card_document_url",
            "social_links",
        )

    def _build_absolute_uri(self, url: str | None) -> str | None:
        if not url:
            return None
        request = self.context.get("request")
        if request is None:
            return url
        return request.build_absolute_uri(url)

    def get_photo_url(self, obj: PersonalInfo):
        if not obj.photo:
            return None
        return self._build_absolute_uri(obj.photo.url)

    def get_id_card_document_url(self, obj: PersonalInfo):
        request = self.context.get("request")
        if not request or request.user != obj.user:
            return None
        if not obj.id_card_image:
            return None
        return self._build_absolute_uri(obj.id_card_image.url)


class SocialLinkInputSerializer(serializers.Serializer):
    name = serializers.ChoiceField(choices=SOCIAL_MEDIA_CHOICES)
    link = serializers.URLField()
    active = serializers.BooleanField(default=True)


class PersonalInfoUpdateSerializer(serializers.ModelSerializer):
    social_links = serializers.JSONField(required=False)

    class Meta:
        model = PersonalInfo
        fields = (
            "gender",
            "phone",
            "about_me",
            "country",
            "id_type",
            "id_number",
            "photo",
            "id_card_image",
            "social_links",
        )
        extra_kwargs = {
            "photo": {"required": False, "allow_null": True},
            "id_card_image": {"required": False, "allow_null": True},
            "gender": {"required": False, "allow_null": True},
            "phone": {"required": False, "allow_null": True, "allow_blank": True},
            "about_me": {"required": False, "allow_null": True, "allow_blank": True},
            "country": {"required": False, "allow_null": True, "allow_blank": True},
            "id_type": {"required": False, "allow_null": True, "allow_blank": True},
            "id_number": {"required": False, "allow_null": True, "allow_blank": True},
        }

    def validate(self, attrs):
        id_document = attrs.get("id_card_image")
        id_type = attrs.get("id_type")
        id_number = attrs.get("id_number")

        # If the document is being updated keep previously stored metadata when not provided
        if id_document is not None:
            id_type = id_type or self.instance.id_type
            id_number = id_number or self.instance.id_number

        if id_document or self.instance.id_card_image:
            if not (id_type or self.instance.id_type):
                raise serializers.ValidationError(
                    {"id_type": _("ID type is required when an identification document is uploaded.")}
                )
            if not (id_number or self.instance.id_number):
                raise serializers.ValidationError(
                    {"id_number": _("ID number is required when an identification document is uploaded.")}
                )

        return attrs

    def update(self, instance: PersonalInfo, validated_data):
        social_links_data = validated_data.pop("social_links", None)

        social_links_data = self._normalize_social_links(social_links_data)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        instance.profile_complete = self._is_profile_complete(instance)
        instance.save()

        if social_links_data is not None:
            self._sync_social_links(instance.user, social_links_data)

        instance.refresh_from_db()
        return instance

    def _is_profile_complete(self, instance: PersonalInfo) -> bool:
        required_fields = [instance.photo, instance.id_card_image, instance.id_type, instance.id_number]
        return all(required_fields)

    def _normalize_social_links(self, data):
        if data is None:
            return None
        serializer = SocialLinkInputSerializer(data=data, many=True)
        serializer.is_valid(raise_exception=True)
        return serializer.validated_data

    def _sync_social_links(self, user: User, social_links_data):
        keep_ids = []
        for payload in social_links_data:
            link_obj, _ = SocialMedia.objects.update_or_create(
                user=user,
                name=payload["name"],
                defaults={
                    "link": payload["link"],
                    "active": payload.get("active", True),
                },
            )
            keep_ids.append(link_obj.id)

        user.user_social_medias.exclude(id__in=keep_ids).delete()
