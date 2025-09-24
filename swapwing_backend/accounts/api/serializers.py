from django.contrib.auth import get_user_model, password_validation
from django.utils.translation import gettext_lazy as _
from rest_framework import serializers

User = get_user_model()


class UserRegistrationSerializer(serializers.ModelSerializer):
    password2 = serializers.CharField(
        style={"input_type": "password"}, write_only=True, label=_("Confirm password")
    )

    class Meta:
        model = User
        fields = [
            "email",
            "username",
            "first_name",
            "last_name",
            "password",
            "password2",
        ]
        extra_kwargs = {
            "password": {"write_only": True},
        }

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(_("A user with that email already exists."))
        return value

    def validate(self, attrs):
        password = attrs.get("password")
        password2 = attrs.pop("password2", None)
        if password != password2:
            raise serializers.ValidationError({"password": _("Passwords must match.")})
        password_validation.validate_password(password)
        return attrs

    def create(self, validated_data):
        password = validated_data.pop("password")
        username = validated_data.pop("username", None)
        user = User.objects.create_user(
            password=password,
            is_active=False,
            **validated_data,
        )
        if username:
            user.username = username
            user.save(update_fields=["username"])
        return user


class EmailVerificationSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    token = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    def validate(self, attrs):
        if not attrs.get("code") and not attrs.get("token"):
            raise serializers.ValidationError(
                {"code": _("Provide a verification code or token.")}
            )
        return attrs


class ResendEmailVerificationSerializer(serializers.Serializer):
    email = serializers.EmailField()


class PasswordResetSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
