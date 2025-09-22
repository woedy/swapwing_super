from django.urls import path

from garage.api.views import get_user_garage, get_garage_item_detail, get_garage_service_detail, add_garage_item, \
    add_garage_service, delete_garage_item, set_garage_item_premium, list_garage_item, \
    hide_show_garage_item, edit_garage_item, list_item_reactions
from listings.api.view import get_all_listings, get_listing_detail

app_name = 'listings'

urlpatterns = [
    # CLIENT URLS
    path('get-all-listings', get_all_listings, name="get_all_listings"),
    path('listing-detail', get_listing_detail, name="get_listing_detail"),

]
