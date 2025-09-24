"""
URL configuration for mysite project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)

urlpatterns = [
    path("admin/", admin.site.urls),

    # API schema & docs
    path("api/schema/", SpectacularAPIView.as_view(), name="api-schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="api-schema"),
        name="api-docs",
    ),
    path(
        "api/docs/redoc/",
        SpectacularRedocView.as_view(url_name="api-schema"),
        name="api-docs-redoc",
    ),

    # includes
    path("accounts/", include('accounts.urls', 'accounts')),
    # path('accounts/', include('accounts.passwords.urls')),

    path('api/accounts/', include('accounts.api.urls', 'accounts_api')),
    path('api/home_page/', include('home_page.api.urls', 'home_page_api')),
    path('api/garage/', include('garage.api.urls', 'garage_api')),
    path('api/listings/', include('listings.api.urls', 'listings_api')),
    path('api/journeys/', include('journeys.api.urls', 'journeys_api')),
    path('api/challenges/', include('challenges.api.urls', 'challenges_api')),
    path('api/user-profile/', include('user_profile.api.urls', 'user_profile_api')),
]
if settings.DEBUG:
    urlpatterns = urlpatterns + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns = urlpatterns + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
