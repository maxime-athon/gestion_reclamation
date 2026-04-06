from django.db import models
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.models import CustomUser
from .models import Commentaire, HistoriqueStatut, Notification, Ticket
from .permissions import IsAdminRole, IsAuteurOrReadOnly, IsTechnicienOrAdmin
from .serializers import (
    CommentaireSerializer,
    NotificationSerializer,
    TicketListSerializer,
    TicketSerializer,
)

# Ce fichier définit les vues pour l'application "tickets".
# Les vues sont basées sur des viewsets de Django REST Framework, qui fournissent des fonctionnalités CRUD pour les modèles Ticket et Notification. 
# La classe TicketViewSet gère les opérations liées aux tickets, telles que la création, la modification, l'assignation, les commentaires et les statistiques, tandis que la classe NotificationViewSet gère les opérations liées aux notifications, telles que\ la récupération et la mise à jour de l'état de lecture des notifications.
# Les vues utilisent des permissions personnalisées pour contrôler l'accès aux différentes actions en fonction du rôle de l'utilisateur (auteur, technicien, administrateur) et du type d'opération (lecture, écriture). 
# Les vues utilisent également des serializers pour valider les données d'entrée et formater les données de sortie, et des filtres pour permettre la recherche, le tri et le filtrage des tickets et des notifications. 

class TicketViewSet(viewsets.ModelViewSet):#une vue pour gérer les tickets de réclamation, qui permet aux utilisateurs de créer, consulter, modifier et archiver des tickets, ainsi que d'ajouter des commentaires et de changer le statut des tickets.
    permission_classes = [IsAuthenticated, IsAuteurOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['statut', 'priorite', 'type_ticket', 'assigne_a', 'est_archive']
    search_fields = ['titre', 'description']
    ordering_fields = ['date_creation', 'date_modification', 'date_resolution', 'priorite', 'statut']
    ordering = ['-date_creation']

    def get_base_queryset(self):
        return Ticket.objects.select_related('auteur', 'assigne_a').prefetch_related(
            'historique__modifie_par',
            'commentaires__auteur',
        ).annotate(commentaires_count=models.Count('commentaires', distinct=True))

    def get_serializer_class(self):
        if self.action == 'list':
            return TicketListSerializer
        return TicketSerializer

    def get_queryset(self):
        user = self.request.user
        queryset = self.get_base_queryset()

        include_archived = self.request.query_params.get('include_archived') in {'1', 'true', 'True'}
        assigned_only = self.request.query_params.get('assigned') in {'1', 'true', 'True'}

        if user.role == CustomUser.Role.ADMIN:
            if not include_archived:
                queryset = queryset.filter(est_archive=False)
            return queryset

        queryset = queryset.filter(est_archive=False)

        if user.role == CustomUser.Role.CITOYEN:
            return queryset.filter(auteur=user)

        if assigned_only:
            return queryset.filter(assigne_a=user)

        return queryset.filter(models.Q(assigne_a=user) | models.Q(statut=Ticket.Statut.OUVERT))

    def perform_create(self, serializer):
        serializer.save(auteur=self.request.user)

    @action(detail=True, methods=['patch'], permission_classes=[IsTechnicienOrAdmin])
    def changer_statut(self, request, pk=None):
        ticket = self.get_object()
        nouveau_statut = request.data.get('statut')

        if request.user.role == CustomUser.Role.TECHNICIEN and ticket.assigne_a_id != request.user.id:
            return Response(
                {'erreur': 'Ce ticket doit vous etre assigne avant changement de statut.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if nouveau_statut not in dict(Ticket.Statut.choices):
            return Response({'erreur': 'Statut invalide.'}, status=status.HTTP_400_BAD_REQUEST)

        ancien_statut = ticket.statut
        if ancien_statut == nouveau_statut:
            return Response(TicketSerializer(ticket, context={'request': request}).data)

        ticket.statut = nouveau_statut
        ticket.date_resolution = timezone.now() if nouveau_statut == Ticket.Statut.RESOLU else None
        ticket.save(update_fields=['statut', 'date_resolution', 'date_modification'])

        HistoriqueStatut.objects.create(
            ticket=ticket,
            ancien_statut=ancien_statut,
            nouveau_statut=nouveau_statut,
            modifie_par=request.user,
        )

        serializer = TicketSerializer(ticket, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated]) # Plus souple
    def commenter(self, request, pk=None):
        ticket = self.get_object()
        serializer = CommentaireSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        commentaire = serializer.save(ticket=ticket, auteur=request.user)
        return Response(
            CommentaireSerializer(commentaire, context={'request': request}).data,#
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['patch'], permission_classes=[IsAdminRole])
    def assigner(self, request, pk=None):
        ticket = self.get_object()
        technicien_id = request.data.get('technicien_id')

        if technicien_id in (None, ''):
            return Response(
                {'erreur': 'technicien_id est obligatoire.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            technicien = CustomUser.objects.get(id=technicien_id, role=CustomUser.Role.TECHNICIEN)
        except CustomUser.DoesNotExist:
            return Response(
                {'erreur': 'Technicien introuvable.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        ticket.assigne_a = technicien
        if ticket.statut == Ticket.Statut.OUVERT:
            ticket.statut = Ticket.Statut.EN_COURS
        ticket.save(update_fields=['assigne_a', 'statut', 'date_modification'])

        serializer = TicketSerializer(ticket, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[IsAdminRole])
    def statistiques(self, request):
        tickets = Ticket.objects.all()
        today = timezone.localdate()

        by_status = {item['statut']: item['total'] for item in tickets.values('statut').annotate(total=models.Count('id'))}
        by_priority = {item['priorite']: item['total'] for item in tickets.values('priorite').annotate(total=models.Count('id'))}
        by_type = {item['type_ticket']: item['total'] for item in tickets.values('type_ticket').annotate(total=models.Count('id'))}

        payload = {
            'total_tickets': tickets.count(),
            'open_tickets': by_status.get(Ticket.Statut.OUVERT, 0),
            'in_progress_tickets': by_status.get(Ticket.Statut.EN_COURS, 0),
            'resolved_tickets': by_status.get(Ticket.Statut.RESOLU, 0),
            'closed_tickets': by_status.get(Ticket.Statut.CLOS, 0),
            'critical_tickets': by_priority.get(Ticket.Priorite.CRITIQUE, 0),
            'resolved_today': tickets.filter(date_resolution__date=today).count(),
            'par_statut': by_status,
            'par_priorite': by_priority,
            'par_type': by_type,
        }
        return Response(payload)

    @action(detail=True, methods=['post'], permission_classes=[IsAdminRole])
    def archiver(self, request, pk=None):
        ticket = self.get_object()
        if ticket.statut not in [Ticket.Statut.RESOLU, Ticket.Statut.CLOS]:
            return Response(
                {'erreur': 'Seuls les tickets resolus ou clos peuvent etre archives.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if ticket.est_archive:
            return Response({'message': 'Le ticket est deja archive.'})

        ticket.est_archive = True
        ticket.save(update_fields=['est_archive', 'date_modification'])
        return Response({'message': 'Ticket archive avec succes.'})
    
    
class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'patch', 'head', 'options'] 

    def get_queryset(self):
        return Notification.objects.filter(destinataire=self.request.user).select_related('ticket')

    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        notification = self.get_object()
        notification.est_lue = True
        notification.save(update_fields=['est_lue'])
        return Response({'status': 'lue'})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        updated = self.get_queryset().filter(est_lue=False).update(est_lue=True)
        return Response({'updated': updated})

