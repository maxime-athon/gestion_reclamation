from rest_framework.permissions import BasePermission, SAFE_METHODS

class IsAuteurOrReadOnly(BasePermission):
    """
    Permission personnalisée permettant uniquement à l'auteur d'un objet
    de le modifier. Les autres utilisateurs peuvent uniquement le consulter.
    """
    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        return obj.auteur == request.user

class IsTechnicienOrAdmin(BasePermission):
    """
    Autorise l'accès uniquement aux utilisateurs ayant un rôle 
    de Technicien ou d'Administrateur.
    """
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and 
                    request.user.role in ('TECHNICIEN', 'ADMIN'))

class IsAdminRole(BasePermission):
    """
    Restriction stricte pour les actions d'administration globale
    (ex: gestion des utilisateurs, statistiques).
    """
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and 
                    request.user.role == 'ADMIN')