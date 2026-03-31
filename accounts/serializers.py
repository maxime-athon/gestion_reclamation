from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from accounts.models import CustomUser


class RegisterSerializer(serializers.ModelSerializer):
    """
    Serializer pour l'inscription.
    - Valide email, mot de passe et rôle.
    - Crée un nouvel utilisateur.
    """
    password = serializers.CharField(write_only=True, validators=[validate_password])

    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'password', 'role']

    def create(self, validated_data):
        # create_user gère automatiquement le hachage sécurisé (PBKDF2/Argon2)
        user = CustomUser.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            role=validated_data.get('role', 'CITOYEN')
        )
        return user


class UserSerializer(serializers.ModelSerializer):
    """
    Serializer pour afficher les informations d'un utilisateur.
    Utilisé dans ProfileView.
    """
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'role', 'first_name', 'last_name']