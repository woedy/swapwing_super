from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.authentication import TokenAuthentication
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from user_profile.api.serializers import (
    PersonalInfoSerializer,
    PersonalInfoUpdateSerializer,
)
from user_profile.models import PersonalInfo

User = get_user_model()


class ProfileMeView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def _get_personal_info(self, request) -> PersonalInfo:
        personal_info, _ = PersonalInfo.objects.get_or_create(user=request.user)
        return personal_info

    @extend_schema(
        summary="Retrieve the authenticated trader profile",
        tags=["Profile"],
        responses=PersonalInfoSerializer,
    )
    def get(self, request):
        serializer = PersonalInfoSerializer(
            self._get_personal_info(request),
            context={"request": request},
        )
        return Response(serializer.data)

    @extend_schema(
        summary="Update the authenticated trader profile",
        tags=["Profile"],
        request=PersonalInfoUpdateSerializer,
        responses=PersonalInfoSerializer,
    )
    def patch(self, request):
        personal_info = self._get_personal_info(request)
        serializer = PersonalInfoUpdateSerializer(
            personal_info,
            data=request.data,
            partial=True,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)
        updated_info = serializer.save()

        response_serializer = PersonalInfoSerializer(
            updated_info,
            context={"request": request},
        )
        return Response(response_serializer.data, status=status.HTTP_200_OK)


class ProfileDetailView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="Retrieve another trader's public profile",
        tags=["Profile"],
        responses=PersonalInfoSerializer,
    )
    def get(self, request, user_id: str):
        user = get_object_or_404(User, user_id=user_id)
        personal_info = PersonalInfo.objects.get(user=user)
        serializer = PersonalInfoSerializer(
            personal_info,
            context={"request": request},
        )
        return Response(serializer.data)
