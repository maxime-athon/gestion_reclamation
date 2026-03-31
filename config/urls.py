"""
URL configuration for le projet Django Gestion des Réclamations.

Ce fichier définit toutes les routes principales :
- Administration Django
- Authentification JWT (login, refresh)
- Inscription et profil utilisateur
- API Tickets (CRUD, actions personnalisées)
"""

from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

from tickets.views import TicketViewSet
from accounts.views import RegisterView, ProfileView, UserViewSet

# Router DRF pour les ViewSets
router = DefaultRouter()
router.register(r'tickets', TicketViewSet, basename='ticket')
router.register(r'users', UserViewSet, basename='user')

urlpatterns = [
    # Interface d’administration Django
    path('admin/', admin.site.urls),

    # Authentification JWT
    path('api/auth/login/', TokenObtainPairView.as_view(), name='token_obtain'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Gestion des utilisateurs
    path('api/auth/register/', RegisterView.as_view(), name='register'),
    path('api/auth/profil/', ProfileView.as_view(), name='profil'),

    # API Tickets (via router DRF)
    path('api/', include(router.urls)),

    # Auth DRF pour debug (interface de login basique)
    path('api/auth/', include('rest_framework.urls')),
]