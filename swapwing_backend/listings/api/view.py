from rest_framework import status
from rest_framework.authentication import TokenAuthentication
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.contrib.auth import get_user_model

from garage.models import GarageItem
from listings.api.serializers import ListingSerializer, ListingDetailSerializer

User = get_user_model()


@api_view(['GET', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def get_all_listings(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'GET':
        user_id = request.query_params.get('user_id', None)
        company = request.query_params.get('company', None)

        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")
        else:
            all_items = GarageItem.objects.all().filter(is_premium=False).filter(is_listed=True)
            all_items_serializer = ListingSerializer(all_items, many=True)
            if all_items_serializer:
                _data = all_items_serializer.data
                data['all_items'] = _data

            all_premium_items = GarageItem.objects.all().filter(is_premium=True).filter(is_listed=True)
            all_premium_items_serializer = ListingSerializer(all_premium_items, many=True)
            if all_premium_items_serializer:
                _data = all_premium_items_serializer.data
                data['all_premium_items'] = _data


        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)




@api_view(['GET', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def get_listing_detail(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'GET':
        user_id = request.query_params.get('user_id', None)
        item_id = request.query_params.get('item_id', None)

        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")

        if not item_id:
            payload['response'] = "Error"
            errors.append("Item ID Required.")

        else:
            user = User.objects.get(user_id=user_id)
            try:
                listing_detail = GarageItem.objects.get(item_id=item_id)
                listing_detail_serializer = ListingDetailSerializer(listing_detail, many=False)
                if listing_detail_serializer:
                    _data = listing_detail_serializer.data
                    data['listing_detail'] = _data


            except GarageItem.DoesNotExist:
                payload['response'] = "Error"
                errors.append("Item not available.")

        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)
