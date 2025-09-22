from django.contrib import admin

from user_profile.models import PersonalInfo, AdminInfo, Wallet, Address, SocialMedia, EmergencyContact, UserLanguage

admin.site.register(PersonalInfo)
admin.site.register(Wallet)
admin.site.register(AdminInfo)

admin.site.register(Address)
admin.site.register(SocialMedia)
admin.site.register(EmergencyContact)
admin.site.register(UserLanguage)


