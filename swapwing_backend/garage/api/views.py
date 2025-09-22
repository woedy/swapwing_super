from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.authentication import TokenAuthentication
from rest_framework.decorators import permission_classes, api_view, authentication_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from garage.api.serializers import GarageSerializer, GarageItemSerializer, GarageServiceSerializer, \
    GarageItemDetailSerializer, GarageServiceDetailSerializer
from garage.models import Garage, GarageItem, GarageService, CanCounterWith, GarageItemImages, GarageItemVideos, \
    GarageServiceImages, GarageServiceVideos, GarageItemCategory
from mysite.utils import base64_file

User = get_user_model()

@api_view(['GET', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def get_user_garage(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'GET':
        user_id = request.query_params.get('user_id', None)

        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")
        else:
            user = User.objects.get(user_id=user_id)
            try:
                user_garage = Garage.objects.get(user=user)
                user_garage_serializer = GarageSerializer(user_garage, many=False)
                if user_garage_serializer:
                    _data = user_garage_serializer.data
                    data = _data

                # GAGRAGE ITEMS
                garage_item = GarageItem.objects.all().filter(garage=user_garage)
                garage_item_serializer = GarageItemSerializer(garage_item, many=True)
                if garage_item_serializer:
                    _data = garage_item_serializer.data
                    data['garage_items'] = _data

                # GAGRAGE SERVICES
                garage_service = GarageService.objects.all().filter(garage=user_garage)
                garage_service_serializer = GarageServiceSerializer(garage_service, many=True)
                if garage_service_serializer:
                    _data = garage_service_serializer.data
                    data['garage_services'] = _data


            except Garage.DoesNotExist:
                payload['response'] = "Error"
                errors.append("User garage not available.")
                #return Response(payload, status=status.HTTP_404_NOT_FOUND)



        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)


@api_view(['POST', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def add_garage_item(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'POST':
        user_id = request.data.get('user_id', '0')

        item_name = request.data.get('item_name', '0')
        quality = request.data.get('quality', '0')
        description = request.data.get('description', '0')
        reason = request.data.get('reason', '0')


        category = request.data.get('category', '0').split(",")
        #categories = []
        #for cat in category:
        #    categories.append(cat)


        meet_up_loc = request.data.get('meet_up_loc', '0')
        meet_up_lat = request.data.get('meet_up_lat', '0')
        meet_up_lng = request.data.get('meet_up_lng', '0')

        add_generic_loc = request.data.get('add_generic_loc', '0')
        if add_generic_loc == "true":
            add_generic_loc = True
        elif add_generic_loc == "false":
            add_generic_loc = False


        bid_starts = request.data.get('bid_starts', '0')
        duration = request.data.get('duration', '0')

        list_item = request.data.get('list_item', '0')
        if list_item == "true":
            list_item = True
        elif list_item == "false":
            list_item = False

        auto_relist = request.data.get('auto_relist', '0')
        if auto_relist == "true":
            auto_relist = True
        elif auto_relist == "false":
            auto_relist = False

        counter_withs = request.data.get('counter_withs', '0').split(",")
        with_anything = request.data.get('with_anything', '0')
        if with_anything == "true":
            with_anything = True
        elif with_anything == "false":
            with_anything = False




        item_images = request.FILES.getlist('item_images')
        item_videos = request.data.get('item_videos', '0')




        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")
        else:

            print("#########################")
            print(user_id)

            print(item_name)
            print(description)
            print(reason)
            print(quality)

            print(category)

            print(meet_up_loc)
            print(meet_up_lat)
            print(meet_up_lng)
            print(add_generic_loc)

            print(bid_starts)
            print(duration)
            print(list_item)
            print(auto_relist)

            print(counter_withs)
            print(with_anything)

            print(item_images)
            print(item_videos)
#


            user = User.objects.get(user_id=user_id)
            garage = Garage.objects.get(user=user)
#
#
#
#
#
#
            new_item = GarageItem.objects.create(
                garage=garage,
                item_name=item_name,
                description=description,
                reason=reason,
                quality=quality,


                meet_up_loc=meet_up_loc,
                meet_up_lat=meet_up_lat,
                meet_up_lng=meet_up_lng,
                add_generic_loc=add_generic_loc,

                bid_starts=bid_starts,
                duration=duration,
                is_listed=list_item,
                auto_relist=auto_relist,

                with_anything=with_anything,

                item_owner=user

            )

            for item in counter_withs:
                can_counter = CanCounterWith.objects.create(
                    item=new_item,
                   item_name=item,
                )

            for item_cat in category:
                category = GarageItemCategory.objects.create(
                    item=new_item,
                   category_name=item_cat,
                )

            data['item_id'] = new_item.item_id


            for image in item_images:
                item_image = GarageItemImages.objects.create(
                    garage_item=new_item,
                    image=image
                )
                #print(image)

            for video in item_videos:
                item_video = GarageItemVideos.objects.create(
                    garage_item=new_item,
                    video=video
                )
                #print(video)


        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)

@api_view(['GET', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def get_garage_item_detail(request):
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
                garage_item = GarageItem.objects.get(item_id=item_id)
                garage_item_detail_serializer = GarageItemDetailSerializer(garage_item, many=False)
                if garage_item_detail_serializer:
                    _data = garage_item_detail_serializer.data
                    data['garage_item_detail'] = _data


            except GarageItem.DoesNotExist:
                payload['response'] = "Error"
                errors.append("Item not available.")

        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)

@api_view(['POST', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def set_garage_item_premium(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'POST':
        user_id = request.data.get('user_id', '0')
        item_id = request.data.get('item_id', '0')



        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")
        else:

            print("#########################")
            print(user_id)
            #print(garage_id)


            user = User.objects.get(user_id=user_id)
            garage_item = GarageItem.objects.get(item_id=item_id)

            if garage_item.is_premium is True:
                garage_item.is_premium = False
                garage_item.save()
            else:
                garage_item.is_premium = True
                garage_item.save()





        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)

@api_view(['POST', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def list_garage_item(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'POST':
        user_id = request.data.get('user_id', '0')
        item_id = request.data.get('item_id', '0')



        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")
        else:

            print("#########################")
            print(user_id)
            #print(garage_id)


            user = User.objects.get(user_id=user_id)
            garage_item = GarageItem.objects.get(item_id=item_id)

            if garage_item.is_listed == True:
                garage_item.is_listed = False
                garage_item.save()
            else:
                garage_item.is_listed = True
                garage_item.save()





        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)

@api_view(['POST', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def hide_show_garage_item(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'POST':
        user_id = request.data.get('user_id', '0')
        item_id = request.data.get('item_id', '0')



        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")
        else:

            print("#########################")
            print(user_id)
            #print(garage_id)


            user = User.objects.get(user_id=user_id)
            garage_item = GarageItem.objects.get(item_id=item_id)


            if garage_item.hidden == True:
                garage_item.hidden = False
                garage_item.save()
            else:
                garage_item.hidden = True
                garage_item.save()





        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)

@api_view(['POST', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def delete_garage_item(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'POST':
        user_id = request.data.get('user_id', '0')
        item_id = request.data.get('item_id', '0')



        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")
        else:

            print("#########################")
            print(user_id)
            #print(garage_id)


            user = User.objects.get(user_id=user_id)
            garage_item = GarageItem.objects.get(item_id=item_id)

            garage_item.delete()





        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)


@api_view(['POST', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def edit_garage_item(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'POST':
        user_id = request.data.get('user_id', '0')
        item_id = request.data.get('item_id', '0')
        item_name = request.data.get('item_name', '0')
        item_type = request.data.get('item_type', '0')
        quality = request.data.get('quality', '0')
        category = request.data.get('category', '0')
        primary_material = request.data.get('primary_material', '0')
        description = request.data.get('description', '0')
        reason = request.data.get('reason', '0')
        cost_in_credit = request.data.get('cost_in_credit', '0')



        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")
        else:

            print("#########################")
            print(user_id)
            #print(garage_id)
            print(item_name)
            print(item_type)
            print(quality)
            print(category)
            print(primary_material)
            print(description)
            print(reason)
            print(cost_in_credit)

            user = User.objects.get(user_id=user_id)
            item = GarageItem.objects.get(item_id=item_id)

            item.item_name = item_name
            item.item_type = item_type
            item.quality = quality
            item.category = category
            item.primary_material = primary_material
            item.description = description
            item.reason = reason
            item.cost_in_credits = cost_in_credit

            item.save()

        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)

@api_view(['GET', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def list_item_reactions(request):
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
        else:
            try:
                garage_item = GarageItem.objects.get(item_id=item_id)
                all_reactions = garage_item.reactions.all()
                print(all_reactions)


            except GarageItem.DoesNotExist:
                payload['response'] = "Error"
                errors.append("Item not available.")
                #return Response(payload, status=status.HTTP_404_NOT_FOUND)



        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)


#################
## SERVICEEEE
##############


@api_view(['GET', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def get_garage_service_detail(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'GET':
        user_id = request.query_params.get('user_id', None)
        service_id = request.query_params.get('service_id', None)

        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")

        if not service_id:
            payload['response'] = "Error"
            errors.append("Service ID Required.")

        else:
            user = User.objects.get(user_id=user_id)
            try:
                garage_service = GarageService.objects.get(service_id=service_id)
                garage_service_detail_serializer = GarageServiceDetailSerializer(garage_service, many=False)
                if garage_service_detail_serializer:
                    _data = garage_service_detail_serializer.data
                    data['garage_service_detail'] = _data


            except GarageService.DoesNotExist:
                payload['response'] = "Error"
                errors.append("Service not available.")

        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)



@api_view(['POST', ])
@permission_classes([IsAuthenticated, ])
@authentication_classes([TokenAuthentication, ])
def add_garage_service(request):
    payload = {}
    user_data = {}
    data = {}
    errors = []

    if request.method == 'POST':
        user_id = request.data.get('user_id', '0')
        #garage_id = request.data.get('garage_id', '0')
        service_name = request.data.get('service_name', '0')
        service_type = request.data.get('service_type', '0')
        avg_time = request.data.get('avg_time', '0')
        description = request.data.get('description', '0')
        reason = request.data.get('reason', '0')
        cost_in_credit = request.data.get('cost_in_credit', '0')
        service_images = request.data.get('service_images', '0')
        service_videos = request.data.get('service_videos', '0')




        if not user_id:
            payload['response'] = "Error"
            errors.append("User ID Required.")
        else:

            print("#########################")
            print(user_id)
            #print(garage_id)
            print(service_name)
            print(service_type)
            print(avg_time)
            print(description)
            print(reason)
            print(cost_in_credit)


            user = User.objects.get(user_id=user_id)
            garage = Garage.objects.get(user=user)






            new_service = GarageService.objects.create(
                garage=garage,
                service_name=service_name,
                service_type=service_type,
                avg_time=avg_time,
                description=description,
                reason=reason,
                cost_in_credits=cost_in_credit,

            )




            for image in service_images:
                service_image = GarageServiceImages.objects.create(
                    garage_service=new_service,
                    image=base64_file(image)
                )
                #print(image)

            for video in service_videos:
                service_video = GarageServiceVideos.objects.create(
                    garage_service=new_service,
                    video=base64_file(video)
                )
                #print(video)


        if errors:
            payload['errors'] = errors
            return Response(payload, status=status.HTTP_404_NOT_FOUND)

        payload['response'] = "Successful"
        payload['data'] = data

        return Response(payload, status=status.HTTP_200_OK)




