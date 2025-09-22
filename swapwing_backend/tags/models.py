from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import models
from django.db.models.signals import pre_save

User = settings.AUTH_USER_MODEL

class Tag(models.Model):
    name = models.CharField(max_length=120)
    active = models.BooleanField(default=True)

    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


