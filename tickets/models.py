from django.db import models
from django.conf import settings

# Ce fichier définit les modèles de données pour l'application "tickets". 
# Il contient les classes Ticket, Commentaire, HistoriqueStatut et Notification,
# qui représentent respectivement les tickets de réclamation, les commentaires associés à ces tickets, 
# l'historique des changements de statut des tickets et les notifications envoyées aux utilisateurs. 
# Chaque classe utilise des champs appropriés pour stocker les informations nécessaires et des relations entre les modèles sont établies à l'aide de ForeignKey.

class Ticket(models.Model):
    """
    Représente une réclamation ou une demande soumise par un utilisateur.
    Gère le cycle de vie du ticket via les statuts et les assignations.
    """
    class TypeTicket(models.TextChoices):
        INCIDENT = 'INCIDENT', 'Incident technique'
        RECLAMATION = 'RECLAMATION', 'Réclamation'
        DEMANDE = 'DEMANDE', 'Demande de service'

    class Statut(models.TextChoices):
        OUVERT = 'OUVERT', 'Ouvert'
        EN_COURS = 'EN_COURS', 'En cours'
        RESOLU = 'RESOLU', 'Résolu'
        CLOS = 'CLOS', 'Clos'

    class Priorite(models.TextChoices):
        BASSE = 'BASSE', 'Basse'
        NORMALE = 'NORMALE', 'Normale'
        HAUTE = 'HAUTE', 'Haute'
        CRITIQUE = 'CRITIQUE', 'Critique'

    titre = models.CharField(max_length=200)
    description = models.TextField()
    type_ticket = models.CharField(max_length=15, choices=TypeTicket.choices, default=TypeTicket.INCIDENT)
    statut = models.CharField(max_length=10, choices=Statut.choices, default=Statut.OUVERT)
    priorite = models.CharField(max_length=10, choices=Priorite.choices, default=Priorite.NORMALE)
    auteur = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='tickets_crees')
    assigne_a = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='tickets_assignes')
    date_creation = models.DateTimeField(auto_now_add=True)
    date_modification = models.DateTimeField(auto_now=True)
    date_resolution = models.DateTimeField(null=True, blank=True)
    est_archive = models.BooleanField(default=False)

    def __str__(self):
        return f"#{self.id} - [{self.statut}] {self.titre}"

class Commentaire(models.Model):
    """Commentaires postés par les citoyens ou techniciens sur un ticket spécifique."""
    ticket = models.ForeignKey(
        Ticket, on_delete=models.CASCADE, related_name='commentaires')
    auteur = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    contenu = models.TextField()
    date = models.DateTimeField(auto_now_add=True)

class HistoriqueStatut(models.Model):
    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='historique')
    ancien_statut = models.CharField(max_length=10)
    nouveau_statut = models.CharField(max_length=10)
    date_changement = models.DateTimeField(auto_now_add=True)
    modifie_par = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True)

class Notification(models.Model):
    """Système de notifications pour alerter les utilisateurs des actions à entreprendre."""
    destinataire = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    titre = models.CharField(max_length=100)
    message = models.TextField()
    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, null=True, blank=True)
    est_lue = models.BooleanField(default=False)
    date_creation = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date_creation']