from rest_framework import serializers
from django.contrib.auth import get_user_model

from garage.models import GarageItem, GarageItemImages, GarageItemComment, CanCounterWith, GarageItemCategory, \
    GarageItemVideos
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

class ListingUserPersonalInfoSerializer(serializers.ModelSerializer):

    class Meta:
        model = PersonalInfo
        fields = ['id', 'photo', 'is_online']

class ListingUserSerializer(serializers.ModelSerializer):
    user_personal_info = ListingUserPersonalInfoSerializer(many=False)

    class Meta:
        model = User
        fields = ['user_id', 'last_name', 'username', 'first_name', 'user_personal_info']


class GarageItemListingImagesSerializer(serializers.ModelSerializer):

    class Meta:
        model = GarageItemImages
        fields = ['id', 'garage_item', 'image']



class ListingSerializer(serializers.ModelSerializer):
    garage_item_images = serializers.SerializerMethodField()
    item_owner = ListingUserSerializer(many=False)



    class Meta:
        model = GarageItem
        fields = ['id', 'item_id', 'item_name', 'bid_starts', 'ends_in', 'distance', 'is_premium', 'garage_item_images', 'item_owner', ]

    def get_garage_item_images(self, obj):
        first_image = obj.garage_item_images.first()
        if first_image:
            return GarageItemListingImagesSerializer(first_image).data
        return None



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


class ListingDetailSerializer(serializers.ModelSerializer):
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

