from rest_framework.permissions import BasePermission, SAFE_METHODS

class IsAuteurOrReadOnly(BasePermission):
    """Seul l'auteur peut modifier son ticket."""
    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        return obj.auteur == request.user

class IsTechnicienOrAdmin(BasePermission):
    """Seuls les techniciens et admins peuvent changer le statut."""
    def has_permission(self, request, view):
        return request.user.role in ('TECHNICIEN', 'ADMIN')

class IsAdminRole(BasePermission):
    """Réservé aux administrateurs."""
    def has_permission(self, request, view):
        return request.user.role == 'ADMIN'