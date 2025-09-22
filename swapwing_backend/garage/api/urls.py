from django.urls import path

from garage.api.views import get_user_garage, get_garage_item_detail, get_garage_service_detail, add_garage_item, \
    add_garage_service, delete_garage_item, set_garage_item_premium, list_garage_item, \
    hide_show_garage_item, edit_garage_item, list_item_reactions

app_name = 'garage'

urlpatterns = [
    # CLIENT URLS
    path('user-garage', get_user_garage, name="user_garage"),
    path('garage-item-detail', get_garage_item_detail, name="get_garage_item_detail"),
    path('garage-service-detail', get_garage_service_detail, name="get_garage_service_detail"),

    path('add-garage-item', add_garage_item, name="add_garage_item"),
    path('edit-garage-item', edit_garage_item, name="edit_garage_item"),
    path('list-garage-item', list_garage_item, name="list_garage_item"),
    path('hide-show-garage-item', hide_show_garage_item, name="hide_show_garage_item"),
    path('delete-garage-item', delete_garage_item, name="delete_garage_item"),
    path('set-garage-item-premium', set_garage_item_premium, name="set_garage_item_premium"),
    path('list-item-reactions', list_item_reactions, name="list_item_reactions"),

    path('add-garage-service', add_garage_service, name="add_garage_service"),

]
