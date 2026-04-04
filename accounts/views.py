# imports nécessaires pour les vues de l'application accounts, 
# qui gèrent l'authentification, l'inscription, la gestion des profils et les opérations d'administration des utilisateurs.

from django.conf import settings
from django_filters.rest_framework import DjangoFilterBackend
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from rest_framework import filters, generics, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from accounts.models import CustomUser
from accounts.serializers import (
    AdminUserSerializer,
    CustomTokenObtainPairSerializer,
    ForgotPasswordConfirmSerializer,
    ForgotPasswordRequestSerializer,
    RegisterSerializer,
    UserSerializer,
)
from tickets.permissions import IsAdminRole


class CustomTokenObtainPairView(TokenObtainPairView):#une vue personnalisée pour l'obtention de tokens JWT
    serializer_class = CustomTokenObtainPairSerializer


class RegisterView(generics.CreateAPIView): #une vue générique pour l'inscription des utilisateurs, qui utilise le serializer RegisterSerializer pour valider les données d'entrée et créer un nouvel utilisateur.
    queryset = CustomUser.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class ForgotPasswordRequestView(APIView):#une vue pour gérer les demandes de réinitialisation de mot de passe, qui utilise le serializer ForgotPasswordRequestSerializer pour valider l'email fourni, créer un jeton de réinitialisation et envoyer un email à l'utilisateur avec les instructions pour réinitialiser son mot de passe.
    permission_classes = [permissions.AllowAny]

    def post(self, request): 
        serializer = ForgotPasswordRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        token = serializer.create_reset_token()
        #
        email = serializer.validated_data['email']
        user = CustomUser.objects.filter(email=email).first()

        if token and user:
            # Préparation du contenu HTML
            context = {'token': token, 'user': user}
            html_message = render_to_string('accounts/password_reset_email.html', context)
            plain_message = strip_tags(html_message)

            send_mail(
                subject='Réinitialisation de votre mot de passe',
                message=plain_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                html_message=html_message,
            )
            
        payload = {'message': 'Si cette adresse existe, un lien de reinitialisation a ete prepare.'}
        return Response(payload)


class ForgotPasswordConfirmView(APIView):#une vue pour gérer la confirmation de la réinitialisation de mot de passe, qui utilise le serializer ForgotPasswordConfirmSerializer pour valider le jeton fourni et le nouveau mot de passe, puis met à jour le mot de passe de l'utilisateur correspondant si le jeton est valide.
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ForgotPasswordConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({'message': 'Votre mot de passe a ete reinitialise avec succes.'})


class ProfileView(APIView):#une vue pour gérer les opérations de profil de l'utilisateur connecté, qui permet à l'utilisateur de voir et de mettre à jour ses propres informations de profil en utilisant le serializer UserSerializer.
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class UserViewSet(viewsets.ModelViewSet):#une vue pour gérer les opérations d'administration des utilisateurs, qui permet aux administrateurs de voir, créer, mettre à jour et désactiver les comptes utilisateurs en utilisant le serializer AdminUserSerializer. 
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['role', 'is_active']
    search_fields = ['first_name', 'last_name', 'username', 'email']
    ordering_fields = ['date_joined', 'first_name', 'last_name', 'email']
    ordering = ['-date_joined']

    def get_queryset(self):#logique pour récupérer la liste des utilisateurs, qui est triée par date d'inscription de manière décroissante pour afficher les utilisateurs les plus récents en premier.
        return CustomUser.objects.all().order_by('-date_joined')

    def get_serializer_class(self):
        return AdminUserSerializer

    @action(detail=True, methods=['patch'], url_path='toggle-active')#pour l'action personnalisée "toggle-active" qui permet aux administrateurs de basculer l'état actif d'un utilisateur (activer ou désactiver un compte) en envoyant une requête PATCH à l'URL correspondante.
    def toggle_active(self, request, pk=None):
        user = self.get_object()
        is_active = request.data.get('is_active')
        if is_active is None:
            return Response({'erreur': 'Le champ is_active est obligatoire.'}, status=status.HTTP_400_BAD_REQUEST)
        user.is_active = bool(is_active)
        user.save(update_fields=['is_active'])
        return Response(self.get_serializer(user).data)
