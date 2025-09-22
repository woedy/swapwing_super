from django.contrib import admin

# Register your models here.
from django.contrib import admin

# Register your models here.
from garage.models import GarageServiceVideos, GarageServiceImages, GarageService, GarageItemVideos, GarageItemImages, \
    GarageItem, Garage, UserDesire, CanCounterWith, GarageServiceComment, GarageItemComment, GarageItemCategory

admin.site.register(UserDesire)
admin.site.register(Garage)
admin.site.register(GarageItem)
admin.site.register(GarageItemCategory)
admin.site.register(CanCounterWith)
admin.site.register(GarageItemImages)
admin.site.register(GarageItemVideos)
admin.site.register(GarageItemComment)

admin.site.register(GarageService)
admin.site.register(GarageServiceImages)
admin.site.register(GarageServiceVideos)
admin.site.register(GarageServiceComment)

