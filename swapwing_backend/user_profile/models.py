import os
import random

from django.conf import settings
from django.db import models
from django.db.models.signals import post_save

User = settings.AUTH_USER_MODEL

def get_file_ext(filepath):
    base_name = os.path.basename(filepath)
    name, ext = os.path.splitext(base_name)
    return name, ext


def upload_image_path(instance, filename):
    new_filename = random.randint(1, 3910209312)
    name, ext = get_file_ext(filename)
    final_filename = '{new_filename}{ext}'.format(new_filename=new_filename, ext=ext)
    return "users/{new_filename}/{final_filename}".format(
        new_filename=new_filename,
        final_filename=final_filename
    )


def upload_id_card_path(instance, filename):
    new_filename = random.randint(1, 3910209312)
    name, ext = get_file_ext(filename)
    final_filename = '{new_filename}{ext}'.format(new_filename=new_filename, ext=ext)
    return "id_cards/{new_filename}/{final_filename}".format(
        new_filename=new_filename,
        final_filename=final_filename
    )

def get_default_profile_image():
    return "defaults/default_profile_image.png"


GENDER_CHOICES = (
    ('Male', 'Male'),
    ('Female', 'Female'),

)



SOCIAL_MEDIA_CHOICES = (
    ('Facebook', 'Facebook'),
    ('Twitter', 'Twitter'),
    ('Youtube', 'Youtube'),
    ('Instagram', 'Instagram'),
    ('Whatsapp', 'Whatsapp'),
    ('TikTok', 'TikTok'),
    ('LinkedIn', 'LinkedIn'),
    ('Viber', 'Viber'),
    ('Snapchat', 'Snapchat'),
    ('Telegram', 'Telegram'),

)


class SocialMedia(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_social_medias')
    name = models.CharField(max_length=255, null=True, blank=True, choices=SOCIAL_MEDIA_CHOICES)
    link = models.CharField(max_length=1000, null=True, blank=True)
    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)



class PersonalInfo(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='user_personal_info')
    gender = models.CharField(max_length=100, choices=GENDER_CHOICES, blank=True, null=True)
    photo = models.ImageField(upload_to=upload_image_path, null=True, blank=True, default=get_default_profile_image)

    id_card_image = models.ImageField(upload_to=upload_id_card_path, null=True, blank=True)
    id_type = models.CharField(max_length=255, null=True, blank=True)
    id_number = models.CharField(max_length=255, null=True, blank=True)

    country = models.CharField(max_length=255, null=True, blank=True)

    dob = models.DateTimeField(null=True, blank=True)
    marital_status = models.BooleanField(default=False, null=True, blank=True)
    phone = models.CharField(max_length=255, null=True, blank=True)
    about_me = models.TextField(blank=True, null=True)

    rating = models.DecimalField(default=0, max_digits=30, decimal_places=15, null=True, blank=True)
    points = models.DecimalField(default=0, max_digits=30, decimal_places=15, null=True, blank=True)
    trades_made = models.IntegerField(default=0, null=True, blank=True)

    profile_complete = models.BooleanField(default=False)
    verified = models.BooleanField(default=False)

    location_name = models.CharField(max_length=200, null=True, blank=True)
    distance = models.CharField(default="0.0km", max_length=200, null=True, blank=True)
    lat = models.DecimalField(max_digits=30, decimal_places=15, null=True, blank=True)
    lng = models.DecimalField(max_digits=30, decimal_places=15, null=True, blank=True)

    active = models.BooleanField(default=False)
    is_online = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.user.email


def post_save_personal_info(sender, instance, *args, **kwargs):
    if not instance.photo:
        instance.photo = get_default_profile_image()

post_save.connect(post_save_personal_info, sender=PersonalInfo)


CURRENCY_CHOICE = (
    ('GHC', 'GHC'),
    ('USD', 'USD'),
    ('NIRA', 'NIRA'),
)


class Wallet(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='user_wallet')
    currency = models.CharField(default="GHC", max_length=255, null=True, blank=True, choices=CURRENCY_CHOICE)
    balance = models.CharField(default=0, max_length=255, null=True, blank=True)
    bonus = models.CharField(default=0, max_length=255, null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class AdminInfo(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='admin_info')
    gender = models.CharField(max_length=100, choices=GENDER_CHOICES, blank=True, null=True)
    photo = models.ImageField(upload_to=upload_image_path, null=True, blank=True, default=get_default_profile_image)
    dob = models.DateTimeField(null=True, blank=True)
    marital_status = models.BooleanField(default=False, null=True, blank=True)
    phone = models.CharField(max_length=255, null=True, blank=True)
    about_me = models.TextField(blank=True, null=True)

    profile_complete = models.BooleanField(default=False)
    verified = models.BooleanField(default=False)

    location_name = models.CharField(max_length=200, null=True, blank=True)
    lat = models.DecimalField(max_digits=30, decimal_places=15, null=True, blank=True)
    lng = models.DecimalField(max_digits=30, decimal_places=15, null=True, blank=True)

    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.user.email


def post_save_admin_info(sender, instance, *args, **kwargs):
    if not instance.photo:
        instance.photo = get_default_profile_image()

post_save.connect(post_save_admin_info, sender=AdminInfo)




class Address(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_addresses')
    address_line_1 = models.CharField(max_length=255, null=True, blank=True)
    address_line_2 = models.CharField(max_length=255, null=True, blank=True)
    country = models.CharField(max_length=255, null=True, blank=True)
    region = models.CharField(max_length=255, null=True, blank=True)
    city = models.CharField(max_length=255, null=True, blank=True)
    town = models.CharField(max_length=255, null=True, blank=True)
    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


RELATIONSHIP_CHOICES = (
    ('Mother', 'Mother'),
    ('Father', 'Father'),
    ('Sibling', 'Sibling'),
)


class EmergencyContact(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_emergency_contacts')
    full_name = models.CharField(max_length=255, null=True, blank=True)
    relationship = models.CharField(choices=RELATIONSHIP_CHOICES, max_length=255, null=True, blank=True)
    email = models.EmailField(null=True, blank=True)
    phone = models.CharField(max_length=255, null=True, blank=True)
    address_line_1 = models.CharField(max_length=255, null=True, blank=True)
    address_line_2 = models.CharField(max_length=255, null=True, blank=True)
    country = models.CharField(max_length=255, null=True, blank=True)
    region = models.CharField(max_length=255, null=True, blank=True)
    city = models.CharField(max_length=255, null=True, blank=True)
    town = models.CharField(max_length=255, null=True, blank=True)
    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class UserLanguage(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_languages')
    language = models.CharField(max_length=255, null=True, blank=True)
    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.user.email + " - " + self.language