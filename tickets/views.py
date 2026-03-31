from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from django.db import models

from .models import Ticket, Commentaire, HistoriqueStatut
from .serializers import (
    TicketSerializer, TicketListSerializer,
    CommentaireSerializer
)
from .permissions import IsAuteurOrReadOnly, IsTechnicienOrAdmin, IsAdminRole


class TicketViewSet(viewsets.ModelViewSet):
    """
    API Endpoints pour les tickets de réclamation.
    
    Permet le CRUD complet avec un filtrage basé sur le rôle utilisateur.
    Inclut des actions personnalisées pour le cycle de vie (statut, assignation, archivage).
    Filtre par défaut les tickets archivés pour les utilisateurs non-admins.
    """

    queryset = Ticket.objects.select_related(
        'auteur', 'assigne_a'
    ).prefetch_related('commentaires', 'historique')

    permission_classes = [IsAuthenticated]

    filter_backends = [
        DjangoFilterBackend,
        filters.SearchFilter,
        filters.OrderingFilter,
    ]
    filterset_fields = ['statut', 'priorite', 'type_ticket', 'assigne_a']
    search_fields = ['titre', 'description']
    ordering_fields = ['date_creation', 'priorite', 'statut']
    ordering = ['-date_creation']

    def get_serializer_class(self):
        """
        Utilise un serializer allégé pour la liste,
        sinon le serializer complet.
        """
        if self.action == 'list':
            return TicketListSerializer
        return TicketSerializer

    def get_queryset(self):
        """
        Retourne les tickets visibles selon le rôle de l'utilisateur :
        - Citoyen : uniquement ses propres tickets.
        - Technicien : tickets qui lui sont assignés + tickets ouverts.
        - Admin : tous les tickets.
        
        Note: Les tickets avec 'est_archive=True' sont exclus de la vue 
        opérationnelle pour ne pas encombrer l'interface.
        """
        user = self.request.user
        base_queryset = Ticket.objects.filter(est_archive=False)

        if user.role == 'CITOYEN':
            return base_queryset.filter(auteur=user)
        if user.role == 'TECHNICIEN':
            return base_queryset.filter(
                models.Q(assigne_a=user) | models.Q(statut='OUVERT')
            )
        return Ticket.objects.all()

    @action(detail=True, methods=['patch'], permission_classes=[IsTechnicienOrAdmin])
    def changer_statut(self, request, pk=None):
        """
        PATCH /api/tickets/{id}/changer_statut/
        Permet à un technicien ou admin de changer le statut d’un ticket.
        Ajoute une entrée dans l’historique.
        """
        ticket = self.get_object()
        nouveau_statut = request.data.get('statut')

        if nouveau_statut not in dict(Ticket.Statut.choices):
            return Response(
                {'erreur': 'Statut invalide.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        ancien_statut = ticket.statut
        ticket.statut = nouveau_statut

        if nouveau_statut == Ticket.Statut.RESOLU:
            ticket.date_resolution = timezone.now()

        ticket.save()

        # Enregistrer l’historique
        HistoriqueStatut.objects.create(
            ticket=ticket,
            ancien_statut=ancien_statut,
            nouveau_statut=nouveau_statut,
            modifie_par=request.user,
        )

        return Response(
            TicketSerializer(ticket, context={'request': request}).data
        )

    @action(detail=True, methods=['post'])
    def commenter(self, request, pk=None):
        """
        POST /api/tickets/{id}/commenter/
        Permet à un utilisateur d’ajouter un commentaire sur un ticket.
        """
        ticket = self.get_object()
        serializer = CommentaireSerializer(data=request.data)

        if serializer.is_valid():
            serializer.save(ticket=ticket, auteur=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['patch'], permission_classes=[IsAdminRole])
    def assigner(self, request, pk=None):
        """
        PATCH /api/tickets/{id}/assigner/
        Permet à l'administrateur d’assigner un ticket à un technicien.
        """
        ticket = self.get_object()
        technicien_id = request.data.get('technicien_id')

        try:
            from accounts.models import CustomUser
            tech = CustomUser.objects.get(id=technicien_id, role='TECHNICIEN')

            ticket.assigne_a = tech
            ticket.statut = Ticket.Statut.EN_COURS
            ticket.save()

            return Response(
                TicketSerializer(ticket, context={'request': request}).data
            )
        except CustomUser.DoesNotExist:
            return Response(
                {'erreur': 'Technicien introuvable.'},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=False, methods=['get'], permission_classes=[IsAdminRole])
    def statistiques(self, request):
        """
        GET /api/tickets/statistiques/
        Retourne des indicateurs clés sur les tickets.
        """
        total = Ticket.objects.count()
        stats_statut = Ticket.objects.values('statut').annotate(total=models.Count('id'))
        stats_priorite = Ticket.objects.values('priorite').annotate(total=models.Count('id'))

        return Response({
            'total_tickets': total,
            'par_statut': stats_statut,
            'par_priorite': stats_priorite,
        })

    @action(detail=True, methods=['post'], permission_classes=[IsAdminRole])
    def archiver(self, request, pk=None):
        """
        POST /api/tickets/{id}/archiver/
        Archive un ticket clos ou résolu.
        """
        ticket = self.get_object()
        if ticket.statut not in [Ticket.Statut.RESOLU, Ticket.Statut.CLOS]:
            return Response({'erreur': 'Seuls les tickets résolus ou clos peuvent être archivés.'}, status=400)
        
        ticket.est_archive = True
        ticket.save()
        return Response({'message': 'Ticket archivé avec succès.'})