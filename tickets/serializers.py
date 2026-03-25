from rest_framework import serializers
from .models import Ticket, Commentaire, HistoriqueStatut
from accounts.models import CustomUser


class UserLightSerializer(serializers.ModelSerializer):
    """
    Serializer léger pour afficher les informations essentielles d'un utilisateur.
    Utilisé dans les tickets, commentaires et historique pour éviter de charger
    toutes les données du modèle CustomUser.
    """
    class Meta:
        model = CustomUser
        fields = ['id', 'first_name', 'last_name', 'email', 'role']


class CommentaireSerializer(serializers.ModelSerializer):
    """
    Serializer pour les commentaires liés à un ticket.
    Inclut l'auteur en lecture seule via UserLightSerializer.
    """
    auteur = UserLightSerializer(read_only=True)

    class Meta:
        model = Commentaire
        fields = ['id', 'auteur', 'contenu', 'date']
        read_only_fields = ['auteur', 'date']


class HistoriqueStatutSerializer(serializers.ModelSerializer):
    """
    Serializer pour l'historique des changements de statut d'un ticket.
    Inclut l'utilisateur ayant modifié le statut.
    """
    modifie_par = UserLightSerializer(read_only=True)

    class Meta:
        model = HistoriqueStatut
        fields = ['id', 'ancien_statut', 'nouveau_statut',
                  'date_changement', 'modifie_par']


class TicketSerializer(serializers.ModelSerializer):
    """
    Serializer principal pour les tickets.
    - Inclut l'auteur et l'utilisateur assigné (lecture seule).
    - Sérialise aussi les commentaires et l'historique liés au ticket.
    - Permet d'assigner un ticket à un technicien via assigne_a_id.
    """
    auteur = UserLightSerializer(read_only=True)
    assigne_a = UserLightSerializer(read_only=True)
    commentaires = CommentaireSerializer(many=True, read_only=True)
    historique = HistoriqueStatutSerializer(many=True, read_only=True)

    # Champ spécial pour assigner un ticket à un technicien
    assigne_a_id = serializers.PrimaryKeyRelatedField(
        source='assigne_a',
        queryset=CustomUser.objects.filter(role='TECHNICIEN'),
        write_only=True,
        required=False,
        allow_null=True
    )

    class Meta:
        model = Ticket
        fields = [
            'id', 'titre', 'description', 'type_ticket',
            'statut', 'priorite', 'auteur', 'assigne_a',
            'assigne_a_id', 'date_creation',
            'date_modification', 'date_resolution',
            'commentaires', 'historique',
        ]
        read_only_fields = ['auteur', 'date_creation', 'date_modification']

    def create(self, validated_data):
        """
        Lors de la création d'un ticket, l'auteur est automatiquement
        défini comme l'utilisateur connecté.
        """
        validated_data['auteur'] = self.context['request'].user
        return super().create(validated_data)


class TicketListSerializer(serializers.ModelSerializer):
    """
    Serializer allégé pour lister les tickets sans charger
    les commentaires et l'historique.
    """
    auteur = UserLightSerializer(read_only=True)
    assigne_a = UserLightSerializer(read_only=True)

    class Meta:
        model = Ticket
        fields = [
            'id', 'titre', 'type_ticket', 'statut',
            'priorite', 'auteur', 'assigne_a', 'date_creation'
        ]