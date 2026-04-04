from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from accounts.models import CustomUser

# Enregistrement du modèle CustomUser dans l'interface d'administration de Django, 
# avec une configuration personnalisée pour afficher les champs pertinents, 
# permettre la recherche et le filtrage, et organiser les champs de manière logique pour la gestion des utilisateurs par les administrateurs du site.
@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = ('email', 'username', 'role', 'is_active', 'is_staff')
    list_filter = ('role', 'is_active', 'is_staff', 'is_superuser')
    search_fields = ('email', 'username', 'first_name', 'last_name')
    ordering = ('email',)
    fieldsets = UserAdmin.fieldsets + (
        ('Profil metier', {'fields': ('role', 'telephone')}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Profil metier', {'fields': ('email', 'role', 'telephone')}),
    )
