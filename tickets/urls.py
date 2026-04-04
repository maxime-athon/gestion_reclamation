from rest_framework.routers import DefaultRouter

from .views import NotificationViewSet, TicketViewSet

# Ce fichier configure les URL pour l'application "tickets". Il utilise un DefaultRouter de Django REST Framework pour enregistrer les routes pour les vues TicketViewSet et NotificationViewSet, ce qui permet de gérer les opérations CRUD sur les tickets et les notifications via l'API. 
# Les URL générées par le router sont ensuite utilisées pour accéder aux différentes fonctionnalités de l'application "tickets" à travers l'API.

router = DefaultRouter()
router.register(r'tickets', TicketViewSet, basename='ticket')
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = router.urls
