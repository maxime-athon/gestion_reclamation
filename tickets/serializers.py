from django.utils import timezone
from rest_framework import serializers

from accounts.models import CustomUser
from .models import Commentaire, HistoriqueStatut, Notification, Ticket

# Ce fichier définit les serializers pour l'application "tickets".
# Les serializers sont utilisés pour convertir les instances de modèles en formats de données (comme JSON) qui peuvent être facilement transmis via l'API, et pour valider les données d'entrée lors de la création ou la mise à jour des objets. 
# Les classes UserLightSerializer, CommentaireSerializer, HistoriqueStatutSerializer, TicketSerializer, TicketListSerializer et NotificationSerializer sont définies pour gérer
# la sérialisation et la validation des données liées aux utilisateurs, commentaires, historique de statut, tickets et notifications respectivement. 
# Chaque serializer utilise des champs appropriés pour représenter les données et inclut des méthodes de validation personnalisées pour garantir l'intégrité des données.

class UserLightSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = CustomUser
        fields = ['id', 'first_name', 'last_name', 'full_name', 'email', 'role']


class CommentaireSerializer(serializers.ModelSerializer):
    auteur = UserLightSerializer(read_only=True)

    class Meta:
        model = Commentaire
        fields = ['id', 'auteur', 'contenu', 'date']
        read_only_fields = ['id', 'auteur', 'date']

    def validate_contenu(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError('Le commentaire ne peut pas etre vide.')
        return value.strip()


class HistoriqueStatutSerializer(serializers.ModelSerializer):
    modifie_par = UserLightSerializer(read_only=True)

    class Meta:
        model = HistoriqueStatut
        fields = ['id', 'ancien_statut', 'nouveau_statut', 'date_changement', 'modifie_par']


class TicketSerializer(serializers.ModelSerializer):
    auteur = UserLightSerializer(read_only=True)
    assigne_a = UserLightSerializer(read_only=True)
    commentaires = CommentaireSerializer(many=True, read_only=True)
    historique = HistoriqueStatutSerializer(many=True, read_only=True)
    commentaires_count = serializers.SerializerMethodField()
    numero_ticket = serializers.SerializerMethodField()
    assigne_a_id = serializers.PrimaryKeyRelatedField(
        source='assigne_a',
        queryset=CustomUser.objects.filter(role=CustomUser.Role.TECHNICIEN),
        write_only=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model = Ticket
        fields = [
            'id',
            'numero_ticket',
            'titre',
            'description',
            'type_ticket',
            'statut',
            'priorite',
            'auteur',
            'assigne_a',
            'assigne_a_id',
            'date_creation',
            'date_modification',
            'date_resolution',
            'commentaires',
            'commentaires_count',
            'historique',
            'est_archive',
        ]
        read_only_fields = ['auteur', 'date_creation', 'date_modification', 'date_resolution']

    def validate_titre(self, value):
        value = value.strip()
        if len(value) < 3:
            raise serializers.ValidationError('Le titre doit contenir au moins 3 caracteres.')
        return value

    def validate_description(self, value):
        value = value.strip()
        if len(value) < 10:
            raise serializers.ValidationError('La description doit contenir au moins 10 caracteres.')
        return value

    def create(self, validated_data):
        validated_data['auteur'] = self.context['request'].user
        return super().create(validated_data)

    def update(self, instance, validated_data):
        statut = validated_data.get('statut', instance.statut)
        if statut == Ticket.Statut.RESOLU:
            validated_data['date_resolution'] = instance.date_resolution or timezone.now()
        else:
            validated_data['date_resolution'] = None
        return super().update(instance, validated_data)

    def get_commentaires_count(self, obj):
        annotated_count = getattr(obj, 'commentaires_count', None)
        if annotated_count is not None:
            return annotated_count
        return obj.commentaires.count()

    def get_numero_ticket(self, obj):
        return f'TK-{obj.id:03d}' if obj.id else None


class TicketListSerializer(serializers.ModelSerializer):
    auteur = UserLightSerializer(read_only=True)
    assigne_a = UserLightSerializer(read_only=True)
    commentaires_count = serializers.SerializerMethodField()
    numero_ticket = serializers.SerializerMethodField()

    class Meta:
        model = Ticket
        fields = [
            'id',
            'numero_ticket',
            'titre',
            'description',
            'type_ticket',
            'statut',
            'priorite',
            'auteur',
            'assigne_a',
            'date_creation',
            'date_resolution',
            'est_archive',
            'commentaires_count',
        ]

    def get_commentaires_count(self, obj):
        annotated_count = getattr(obj, 'commentaires_count', None)
        if annotated_count is not None:
            return annotated_count
        return obj.commentaires.count()

    def get_numero_ticket(self, obj):
        return f'TK-{obj.id:03d}' if obj.id else None


class NotificationSerializer(serializers.ModelSerializer):
    ticket_id = serializers.IntegerField(source='ticket.id', read_only=True)
    type = serializers.SerializerMethodField()
    type_display = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = [
            'id',
            'titre',
            'message',
            'est_lue',
            'date_creation',
            'ticket_id',
            'type',
            'type_display',
        ]
        read_only_fields = ['id', 'titre', 'message', 'date_creation', 'ticket_id', 'type', 'type_display']

    def get_type(self, obj):
        title = (obj.titre or '').lower()
        if 'assigne' in title:
            return 'ASSIGNATION'
        if 'comment' in title or 'message' in title:
            return 'COMMENTAIRE'
        if 'statut' in title or 'mise a jour' in title:
            return 'STATUT'
        return 'INFO'

    def get_type_display(self, obj):
        return self.get_type(obj).replace('_', ' ').title()
