import os
import random

from django.conf import settings
from django.db import models
from django.db.models import Q
from django.db.models.signals import pre_save

from mysite.utils import unique_garage_id_generator, unique_item_id_generator, unique_service_id_generator

User = settings.AUTH_USER_MODEL


def get_filename_ext(filepath):
    base_name = os.path.basename(filepath)
    name, ext = os.path.splitext(base_name)
    return name, ext


def upload_item_image_path(instance, filename):
    new_filename = random.randint(1, 3910209312)
    name, ext = get_filename_ext(filename)
    final_filename = '{new_filename}{ext}'.format(new_filename=new_filename, ext=ext)
    return "item_images/{new_filename}/{final_filename}".format(
        new_filename=new_filename,
        final_filename=final_filename
    )

def upload_item_video_path(instance, filename):
    new_filename = random.randint(1, 3910209312)
    name, ext = get_filename_ext(filename)
    final_filename = '{new_filename}{ext}'.format(new_filename=new_filename, ext=ext)
    return "item_videos/{new_filename}/{final_filename}".format(
        new_filename=new_filename,
        final_filename=final_filename
    )


def upload_service_image_path(instance, filename):
    new_filename = random.randint(1, 3910209312)
    name, ext = get_filename_ext(filename)
    final_filename = '{new_filename}{ext}'.format(new_filename=new_filename, ext=ext)
    return "service_images/{new_filename}/{final_filename}".format(
        new_filename=new_filename,
        final_filename=final_filename
    )

def upload_service_video_path(instance, filename):
    new_filename = random.randint(1, 3910209312)
    name, ext = get_filename_ext(filename)
    final_filename = '{new_filename}{ext}'.format(new_filename=new_filename, ext=ext)
    return "service_videos/{new_filename}/{final_filename}".format(
        new_filename=new_filename,
        final_filename=final_filename
    )



class CanCounterWithManager(models.Manager):
    def search(self, query=None):
        qs = self.get_queryset()

        if query is not None:
            or_lookup = (Q(item_name__icontains=query))

            qs = qs.filter(or_lookup).distinct()
        return qs



class CanCounterWith(models.Model):
    item = models.ForeignKey("GarageItem", on_delete=models.CASCADE, null=True, blank=True, related_name="can_counter_item")
    item_name = models.CharField(max_length=200, null=True, blank=True)
    info = models.TextField(null=True, blank=True)
    mandatory = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = CanCounterWithManager()



class UserDesireManager(models.Manager):
    def search(self, query=None):
        qs = self.get_queryset()

        if query is not None:
            or_lookup = (Q(desire__icontains=query))

            qs = qs.filter(or_lookup).distinct()
        return qs



class UserDesire(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="user_desires")
    desire = models.CharField(max_length=200, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserDesireManager()



class Garage(models.Model):
    garage_id = models.CharField(max_length=120, unique=True, blank=True, null=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="user_garage")
    open = models.BooleanField(default=True)
    location_name = models.CharField(max_length=200, null=True, blank=True)
    distance = models.CharField(default=0.0, max_length=200, null=True, blank=True)
    lat = models.DecimalField(default=0.0, max_digits=30, decimal_places=15, null=True, blank=True)
    lng = models.DecimalField(default=0.0, max_digits=30, decimal_places=15, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


def pre_save_garage_id_receiver(sender, instance, *args, **kwargs):
    if not instance.garage_id:
        instance.garage_id = unique_garage_id_generator(instance)

pre_save.connect(pre_save_garage_id_receiver, sender=Garage)


PRIMARY_MATERIAL_CHOICE = (

    ('Plastic', 'Plastic'),
    ('Metal', 'Metal'),
    ('Ceramic', 'Ceramic'),
    ('Wood', 'Wood'),


)


STATUS_CHOICE = (

    ('Created', 'Created'),
    ('Pending', 'Pending'),
    ('Approved', 'Approved'),
    ('Declined', 'Declined'),
    ('Started', 'Started'),
    ('Ongoing', 'Ongoing'),
    ('Review', 'Review'),
    ('Completed', 'Completed'),
    ('Canceled', 'Canceled'),
)


class GarageItemCategory(models.Model):
    item = models.ForeignKey("GarageItem", on_delete=models.CASCADE, null=True, blank=True, related_name="item_category")
    category_name = models.CharField(max_length=255, null=True, blank=True)


class GarageItem(models.Model):
    item_id = models.CharField(max_length=120, unique=True, blank=True, null=True)
    garage = models.ForeignKey(Garage, on_delete=models.CASCADE, related_name="garage_items")

    item_name = models.CharField(max_length=255, null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    reason = models.TextField(null=True, blank=True)
    quality = models.CharField(max_length=255, null=True, blank=True)

    is_premium = models.BooleanField(default=False)
    is_listed = models.BooleanField(default=False)
    hidden = models.BooleanField(default=False)
    is_item = models.BooleanField(default=True)

    bid_starts = models.DecimalField(default=0.0, max_digits=30, decimal_places=3, null=True, blank=True)
    duration = models.IntegerField(default=0, null=True, blank=True)
    ends_in = models.IntegerField(default=0, null=True, blank=True)
    auto_relist = models.BooleanField(default=False)

    reactions = models.ManyToManyField(User, blank=True, related_name='item_reactions')

    with_anything = models.BooleanField(default=False)

    distance = models.CharField(default=0.0, max_length=200, null=True, blank=True)
    meet_up_loc = models.CharField(max_length=200, null=True, blank=True)
    meet_up_lat = models.DecimalField(default=0.0, max_digits=30, decimal_places=15, null=True, blank=True)
    meet_up_lng = models.DecimalField(default=0.0, max_digits=30, decimal_places=15, null=True, blank=True)
    add_generic_loc = models.BooleanField(default=True)

    status = models.CharField(default="Pending", max_length=255, null=True, blank=True, choices=STATUS_CHOICE)

    item_owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='garage_item_user')

    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


def pre_save_item_id_receiver(sender, instance, *args, **kwargs):
    if not instance.item_id:
        instance.item_id = unique_item_id_generator(instance)

pre_save.connect(pre_save_item_id_receiver, sender=GarageItem)


class GarageItemImages(models.Model):
    garage_item = models.ForeignKey(GarageItem, on_delete=models.CASCADE, related_name="garage_item_images")
    image = models.FileField(upload_to=upload_item_image_path, null=True, blank=True)
    file_name = models.CharField(max_length=1000, null=True, blank=True)
    file_ext = models.CharField(max_length=255, null=True, blank=True)
    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class GarageItemVideos(models.Model):
    garage_item = models.ForeignKey(GarageItem, on_delete=models.CASCADE, related_name="garage_item_videos")
    video = models.FileField(upload_to=upload_service_video_path, null=True, blank=True)
    file_name = models.CharField(max_length=1000, null=True, blank=True)
    file_ext = models.CharField(max_length=255, null=True, blank=True)
    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class GarageItemComment(models.Model):
    garage_item = models.ForeignKey(GarageItem, on_delete=models.CASCADE, related_name="garage_item_comments")
    comment = models.TextField(null=True, blank=True)
    active = models.BooleanField(default=False)
    user = models.ForeignKey(User,  on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class GarageService(models.Model):
    service_id = models.CharField(max_length=120, unique=True, blank=True, null=True)
    garage = models.ForeignKey(Garage, on_delete=models.CASCADE, related_name="garage_service")
    service_name = models.CharField(max_length=255, null=True, blank=True)
    service_type = models.CharField(max_length=255, null=True, blank=True)
    avg_time = models.CharField(max_length=255, null=True, blank=True)
    distance = models.CharField(default=0.0, max_length=200, null=True, blank=True)
    is_premium = models.BooleanField(default=False)
    is_listed = models.BooleanField(default=False)
    hidden = models.BooleanField(default=False)
    is_service = models.BooleanField(default=True)
    available = models.BooleanField(default=False)
    cost_in_credits = models.IntegerField(default=0, null=True, blank=True)
    reactions = models.ManyToManyField(User, blank=True, related_name='service_reactions')
    location_name = models.CharField(max_length=200, null=True, blank=True)
    lat = models.DecimalField(default=0.0, max_digits=30, decimal_places=15, null=True, blank=True)
    lng = models.DecimalField(default=0.0, max_digits=30, decimal_places=15, null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    reason = models.TextField(null=True, blank=True)
    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


def pre_save_service_id_receiver(sender, instance, *args, **kwargs):
    if not instance.service_id:
        instance.service_id = unique_service_id_generator(instance)

pre_save.connect(pre_save_service_id_receiver, sender=GarageService)



class GarageServiceImages(models.Model):
    garage_service = models.ForeignKey(GarageService, on_delete=models.CASCADE, related_name="garage_service_images")
    image = models.FileField(upload_to=upload_service_image_path, null=True, blank=True)
    file_name = models.CharField(max_length=1000, null=True, blank=True)
    file_ext = models.CharField(max_length=255, null=True, blank=True)
    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class GarageServiceVideos(models.Model):
    garage_service = models.ForeignKey(GarageService, on_delete=models.CASCADE, related_name="garage_service_videos")
    video = models.FileField(upload_to=upload_service_video_path, null=True, blank=True)
    file_name = models.CharField(max_length=1000, null=True, blank=True)
    file_ext = models.CharField(max_length=255, null=True, blank=True)
    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class GarageServiceComment(models.Model):
    garage_service = models.ForeignKey(GarageService, on_delete=models.CASCADE, related_name="garage_service_comments")
    comment = models.TextField(null=True, blank=True)
    active = models.BooleanField(default=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

