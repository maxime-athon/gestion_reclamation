#importation des modules nécessaires pour l'administration de l'application de gestion des réclamations, 
# qui inclut les modèles de Ticket, Commentaire, HistoriqueStatut et Notification, 
# ainsi que la personnalisation de l'interface d'administration pour ces modèles.

from django.contrib import admin

from .models import Commentaire, HistoriqueStatut, Notification, Ticket


class CommentaireInline(admin.TabularInline):#une classe d'inline pour afficher les commentaires associés à un ticket dans l'interface d'administration du ticket.
    model = Commentaire
    extra = 0
    readonly_fields = ('auteur', 'contenu', 'date')
    can_delete = False


class HistoriqueInline(admin.TabularInline):#une classe d'inline pour afficher l'historique des changements de statut d'un ticket dans l'interface d'administration du ticket.
    model = HistoriqueStatut
    extra = 0
    readonly_fields = ('ancien_statut', 'nouveau_statut', 'date_changement', 'modifie_par')
    can_delete = False


@admin.register(Ticket)
class TicketAdmin(admin.ModelAdmin):#une classe d'administration personnalisée pour le modèle Ticket, qui définit les champs à afficher dans la liste des tickets, les filtres disponibles, les champs de recherche et les inlines pour les commentaires et l'historique des statuts.
    list_display = ('id', 'titre', 'type_ticket', 'statut', 'priorite', 'auteur', 'assigne_a', 'est_archive')
    list_filter = ('type_ticket', 'statut', 'priorite', 'est_archive')
    search_fields = ('titre', 'description', 'auteur__email', 'assigne_a__email')
    inlines = [CommentaireInline, HistoriqueInline]


@admin.register(Commentaire)
class CommentaireAdmin(admin.ModelAdmin):#une classe d'administration personnalisée pour le modèle Commentaire, qui définit les champs à afficher dans la liste des commentaires et les champs de recherche.
    list_display = ('id', 'ticket', 'auteur', 'date')
    search_fields = ('contenu', 'ticket__titre', 'auteur__email')


@admin.register(Notification)#une classe d'administration personnalisée pour le modèle Notification, qui définit les champs à afficher dans la liste des notifications, les filtres disponibles et les champs de recherche.
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('id', 'destinataire', 'titre', 'ticket', 'est_lue', 'date_creation')
    list_filter = ('est_lue', 'date_creation')
    search_fields = ('titre', 'message', 'destinataire__email')
