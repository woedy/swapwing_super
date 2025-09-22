from django.urls import path

from home_page.api.views.views import user_home_view

app_name = 'home_page'

urlpatterns = [
    # CLIENT URLS
    path('user-home', user_home_view, name="user_home"),

]
