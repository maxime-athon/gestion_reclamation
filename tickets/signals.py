from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

from accounts.models import CustomUser
from .models import Commentaire, Notification, Ticket

# Ce fichier définit les signaux pour l'application "tickets". Les signaux sont utilisés pour déclencher des actions spécifiques en réponse à des événements liés aux modèles, tels que la création ou la mise à jour d'un ticket ou d'un commentaire.
# Les fonctions connectées aux signaux utilisent des décorateurs pour indiquer à Django quand elles doivent être exécutées. 
# Par exemple, lorsqu'un ticket est créé ou mis à jour, des notifications sont envoyées aux administrateurs, au technicien assigné et à l'auteur du ticket pour les informer des changements. 
# De même, lorsqu'un commentaire est ajouté à un ticket, les parties concernées sont notifiées de la nouvelle activité sur le ticket.

def _notify_admins(title, message, ticket):
    admin_ids = CustomUser.objects.filter(
        role=CustomUser.Role.ADMIN,
        is_active=True,
    ).values_list('id', flat=True)
    notifications = [
        Notification(destinataire_id=admin_id, ticket=ticket, titre=title, message=message)
        for admin_id in admin_ids
        if admin_id != ticket.auteur_id
    ]
    if notifications:
        Notification.objects.bulk_create(notifications)


@receiver(pre_save, sender=Ticket)
def cache_previous_ticket_state(sender, instance, **kwargs):
    instance._previous_status = None
    instance._previous_assignee_id = None
    if not instance.pk:
        return

    previous = Ticket.objects.filter(pk=instance.pk).only('statut', 'assigne_a').first()
    if previous:
        instance._previous_status = previous.statut
        instance._previous_assignee_id = previous.assigne_a_id


@receiver(post_save, sender=Ticket)
def notify_ticket_events(sender, instance, created, **kwargs):
    if created:
        _notify_admins(
            title='Nouveau ticket a traiter',
            message=f'Le ticket #{instance.id} vient d etre cree.',
            ticket=instance,
        )
        return

    previous_status = getattr(instance, '_previous_status', None)
    previous_assignee_id = getattr(instance, '_previous_assignee_id', None)

    if instance.assigne_a_id and instance.assigne_a_id != previous_assignee_id:
        Notification.objects.create(
            destinataire=instance.assigne_a,
            ticket=instance,
            titre='Nouveau ticket assigne',
            message=f'Le ticket #{instance.id} vous a ete attribue.',
        )

    if previous_status and previous_status != instance.statut:
        Notification.objects.create(
            destinataire=instance.auteur,
            ticket=instance,
            titre='Mise a jour de votre ticket',
            message=f'Votre ticket #{instance.id} est passe au statut {instance.statut}.',
        )


@receiver(post_save, sender=Commentaire)
def notify_new_comment(sender, instance, created, **kwargs):
    if not created:
        return

    recipient_ids = set()
    if instance.ticket.auteur_id != instance.auteur_id:
        recipient_ids.add(instance.ticket.auteur_id)
    if instance.ticket.assigne_a_id and instance.ticket.assigne_a_id != instance.auteur_id:
        recipient_ids.add(instance.ticket.assigne_a_id)

    notifications = [
        Notification(
            destinataire_id=recipient_id,
            ticket=instance.ticket,
            titre='Nouveau commentaire',
            message=f'Un nouveau message a ete ajoute sur le ticket #{instance.ticket.id}.',
        )
        for recipient_id in recipient_ids
    ]
    if notifications:
        Notification.objects.bulk_create(notifications)
