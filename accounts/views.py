from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from accounts.models import CustomUser
from accounts.serializers import RegisterSerializer, UserSerializer


class RegisterView(generics.CreateAPIView):
    """
    Vue pour l'inscription des utilisateurs.
    Endpoint : POST /api/auth/register/
    - Permet à un citoyen, technicien ou admin de créer un compte.
    - Utilise RegisterSerializer pour valider et créer l'utilisateur.
    """
    queryset = CustomUser.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]  # accessible sans être connecté


class ProfileView(APIView):
    """
    Vue pour consulter le profil de l'utilisateur connecté.
    Endpoint : GET /api/auth/profil/
    - Retourne les informations de l'utilisateur authentifié.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)