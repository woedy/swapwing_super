
from django.contrib.auth import get_user_model
from django.utils.datetime_safe import date
from rest_framework import serializers

from garage.models import Garage, GarageItem, GarageService, GarageItemImages, GarageServiceImages, GarageItemVideos, \
    GarageServiceVideos, GarageItemComment, GarageItemCategory, CanCounterWith
from user_profile.models import PersonalInfo

User = get_user_model()


class ReactionPersonalInfoSerializer(serializers.ModelSerializer):

    class Meta:
        model = PersonalInfo
        fields = ['id', 'photo',]

class ReactionSerializer(serializers.ModelSerializer):
    user_personal_info = ReactionPersonalInfoSerializer(many=False)

    class Meta:
        model = User
        fields = ['user_id', 'email', 'last_name', 'username', 'first_name', 'user_personal_info']


class GarageServiceVideosSerializer(serializers.ModelSerializer):


    class Meta:
        model = GarageServiceVideos
        fields = ['id', 'garage_service', 'video']

class GarageServiceImagesSerializer(serializers.ModelSerializer):

    class Meta:
        model = GarageServiceImages
        fields = ['id', 'garage_service', 'image']



class GarageItemCommentsSerializer(serializers.ModelSerializer):
    user = ReactionSerializer(many=False)

    class Meta:
        model = GarageItemComment
        fields = ['id', 'comment', 'user', 'created_at']

class GarageItemCanCounterWithSerializer(serializers.ModelSerializer):

    class Meta:
        model = CanCounterWith
        fields = ['id', 'item_name']

class GarageItemCategoriesSerializer(serializers.ModelSerializer):

    class Meta:
        model = GarageItemCategory
        fields = ['id', 'category_name']
class GarageItemVideosSerializer(serializers.ModelSerializer):

    class Meta:
        model = GarageItemVideos
        fields = ['id', 'garage_item', 'video']

class GarageItemImagesSerializer(serializers.ModelSerializer):

    class Meta:
        model = GarageItemImages
        fields = ['id', 'garage_item', 'image']



################

# SERVICE DETAIL

###########



class GarageServiceDetailSerializer(serializers.ModelSerializer):
    garage_service_images = GarageServiceImagesSerializer(many=True)
    garage_service_videos = GarageServiceVideosSerializer(many=True)

    class Meta:
        model = GarageService
        fields = ['id', 'garage', 'service_name', 'service_type', 'avg_time', 'is_premium', 'available', 'reactions', 'reason', 'distance', 'location_name', 'lat', 'lng', 'garage_service_images', 'garage_service_videos']


################

# ITEM DETAIL

###########

class GarageItemDetailSerializer(serializers.ModelSerializer):
    garage_item_images = GarageItemImagesSerializer(many=True)
    garage_item_videos = GarageItemVideosSerializer(many=True)
    garage_item_comments = GarageItemCommentsSerializer(many=True)
    item_category = GarageItemCategoriesSerializer(many=True)
    can_counter_item = GarageItemCanCounterWithSerializer(many=True)
    reactions = ReactionSerializer(many=True)

    class Meta:
        model = GarageItem
        fields = ['item_id',

                  'garage',
                  'item_name',
                  'description',
                  'reason',
                  'quality',

                  'item_category',

                  'is_premium',
                  'is_listed',
                  'hidden',
                  'is_item',

                  'bid_starts',
                  'duration',
                  'auto_relist',

                  'reactions',

                  'with_anything',
                  'can_counter_item',

                  'distance',
                  'meet_up_loc',
                  'meet_up_lat',
                  'meet_up_lng',
                  'add_generic_loc',

                  'status',


                  'garage_item_images',
                  'garage_item_videos',

                  'garage_item_comments',

                  ]




################

# GARAGE

###########


class GarageServiceSerializer(serializers.ModelSerializer):
    garage_service_images = serializers.SerializerMethodField()

    class Meta:
        model = GarageService
        fields = ['id', 'service_id', 'garage', 'service_name', 'is_listed', 'hidden', 'reactions', 'garage_service_images']

    def get_garage_service_images(self, obj):
        first_image = obj.garage_service_images.first()
        if first_image:
            return GarageServiceImagesSerializer(first_image).data
        return None



class GarageItemSerializer(serializers.ModelSerializer):
    garage_item_images = serializers.SerializerMethodField()


    class Meta:
        model = GarageItem
        fields = ['id', 'item_id', 'garage', 'item_name', 'is_listed', 'hidden', 'reactions', 'garage_item_images']

    def get_garage_item_images(self, obj):
        first_image = obj.garage_item_images.first()
        if first_image:
            return GarageItemImagesSerializer(first_image).data
        return None

class GarageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Garage
        fields = [
            'garage_id',
            'open',
            'location_name',
            'distance',
            'lat',
            'lng',
            'lng',
        ]


