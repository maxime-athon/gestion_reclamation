#importing necessary modules and views for URL configuration
from django.contrib import admin
from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from accounts.views import (
    CustomTokenObtainPairView,
    ForgotPasswordConfirmView,
    ForgotPasswordRequestView,
    ProfileView,
    RegisterView,
    UserViewSet,
)
from tickets.views import NotificationViewSet, TicketViewSet

# Setting up the router for API endpoints
router = DefaultRouter()
router.register(r'tickets', TicketViewSet, basename='ticket')
router.register(r'users', UserViewSet, basename='user')
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/login/', CustomTokenObtainPairView.as_view(), name='token_obtain'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/register/', RegisterView.as_view(), name='register'),
    path('api/auth/forgot-password/', ForgotPasswordRequestView.as_view(), name='forgot_password_request'),
    path('api/auth/reset-password/', ForgotPasswordConfirmView.as_view(), name='forgot_password_confirm'),
    path('api/auth/profil/', ProfileView.as_view(), name='profil'),
    path('api/', include(router.urls)),
    path('api/auth/', include('rest_framework.urls')),
]
