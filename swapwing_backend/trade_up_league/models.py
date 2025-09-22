import os
import random
from mysite import settings

from django.db import models

from tags.models import Tag

User = settings.AUTH_USER_MODEL

def get_filename_ext(filepath):
    base_name = os.path.basename(filepath)
    name, ext = os.path.splitext(base_name)
    return name, ext
def upload_episode_path(instance, filename):
    new_filename = random.randint(1, 3910209312)
    name, ext = get_filename_ext(filename)
    final_filename = '{new_filename}{ext}'.format(new_filename=new_filename, ext=ext)
    return "episodes/{new_filename}/{final_filename}".format(
        new_filename=new_filename,
        final_filename=final_filename
    )

class Episode(models.Model):
    title = models.CharField(max_length=1000, blank=True, null=True)
    caption = models.TextField(null=True, blank=True)
    video = models.FileField(upload_to=upload_episode_path, null=True, blank=True)
    date_published = models.DateTimeField(null=True, blank=True, verbose_name="date published")
    tags = models.ManyToManyField(Tag, blank=True, related_name='episode_tags')
    shared_episodes = models.ManyToManyField(User, blank=True, related_name='shared_episode_users')

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    likes = models.ManyToManyField(User, blank=True, related_name='episode_likes')
    views = models.IntegerField(default=0, null=True, blank=True)
    trending_no = models.IntegerField(default=0, null=True, blank=True)


    active = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
