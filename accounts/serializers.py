#import des utilitaires Django et DRF
from django.contrib.auth.password_validation import validate_password #pour valider les mots de passe selon les règles définies
from django.core.signing import BadSignature, SignatureExpired, TimestampSigner #pour créer et vérifier des jetons de réinitialisation de mot de passe
from rest_framework import serializers #pour créer des serializers qui convertissent les instances de modèles en formats JSON et vice versa
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer #pour personnaliser le serializer de token JWT

from accounts.models import CustomUser #import du modèle d'utilisateur personnalisé défini dans accounts/models.py

# Un signataire pour les jetons de réinitialisation de mot de passe, avec un sel spécifique pour éviter les 
# collisions avec d'autres usages de TimestampSigner
# (pas encore finalisé, mais prêt à être utilisé dans les vues de réinitialisation de mot de passe)
RESET_PASSWORD_SIGNER = TimestampSigner(salt='accounts.reset_password') 


# Serializers pour les différentes opérations liées aux utilisateurs, 
# comme l'inscription, la mise à jour du profil, la demande de réinitialisation de mot de passe, etc. 
# Ces serializers définissent les champs attendus, 
# les règles de validation et la logique de création/mise à jour des instances de CustomUser.
class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = CustomUser
        fields = [
            'id',
            'username',
            'email',
            'role',
            'first_name',
            'last_name',
            'full_name',
            'telephone',
            'is_active',
        ]
        read_only_fields = ['id', 'email', 'role', 'is_active']


# Un serializer similaire à UserSerializer mais avec des champs supplémentaires et des règles de validation différentes,
# destiné à être utilisé par les administrateurs pour gérer les utilisateurs (création, mise à jour, etc.).
class AdminUserSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(read_only=True)

    class Meta:
        model = CustomUser
        fields = [
            'id',
            'username',
            'email',
            'role',
            'first_name',
            'last_name',
            'full_name',
            'telephone',
            'is_active',
        ]
        read_only_fields = ['id', 'email']


# Un serializer pour l'inscription des utilisateurs, qui inclut des champs pour le mot de passe, 
# le téléphone, le nom complet, etc., ainsi que des règles de validation pour s'assurer que les données sont correctes et cohérentes avant de créer un nouvel utilisateur.
class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, validators=[validate_password])
    phone = serializers.CharField(write_only=True, required=False, allow_blank=True)
    full_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    first_name = serializers.CharField(required=False, allow_blank=True)
    last_name = serializers.CharField(required=False, allow_blank=True)
    role = serializers.ChoiceField(choices=CustomUser.Role.choices, required=False)

    class Meta: #le serializer est basé sur le modèle CustomUser et inclut les champs nécessaires pour l'inscription, avec des règles de validation spécifiques pour certains champs (comme le mot de passe et le rôle).
        model = CustomUser
        fields = [
            'id',
            'username',
            'email',
            'telephone',
            'phone',
            'full_name',
            'first_name',
            'last_name',
            'password',
            'role',
        ]
        read_only_fields = ['id']
        extra_kwargs = {
            'telephone': {'required': False, 'allow_blank': True},
            'username': {'required': False, 'allow_blank': True},
        }

    def validate_email(self, value):#validation personnalisée pour le champ email, qui s'assure que l'email est unique (pas déjà utilisé par un autre utilisateur) et qu'il est formaté de manière cohérente (en minuscules et sans espaces superflus).
        email = value.strip().lower()
        if CustomUser.objects.filter(email=email).exists():
            raise serializers.ValidationError('Un compte existe deja avec cette adresse email.')
        return email

    def validate_role(self, value):#validation personnalisée pour le champ role, qui s'assure que les utilisateurs qui s'inscrivent via ce serializer ne peuvent pas choisir un rôle autre que "CITOYEN", sauf s'ils sont déjà authentifiés en tant qu'administrateurs (ce qui permet aux administrateurs de créer des comptes avec des rôles différents si nécessaire).
        request = self.context.get('request')
        if request and request.user.is_authenticated and getattr(request.user, 'role', None) == CustomUser.Role.ADMIN:
            return value
        if value != CustomUser.Role.CITOYEN:
            raise serializers.ValidationError(
                'L inscription publique est reservee aux comptes citoyens.'
            )
        return value

    def validate(self, attrs):#validation personnalisée globale pour le serializer, qui harmonise les données d'entrée en traitant les champs de manière flexible (par exemple, en permettant d'utiliser "phone" ou "telephone" pour le numéro de téléphone, ou en permettant de fournir un "full_name" qui sera automatiquement divisé en "first_name" et "last_name").
        # Harmonisation du champ téléphone
        phone = attrs.pop('phone', None)
        if phone:
            attrs['telephone'] = phone

        full_name = attrs.pop('full_name', '').strip()
        if full_name and not (attrs.get('first_name') or attrs.get('last_name')):
            name_parts = full_name.split(None, 1)
            attrs['first_name'] = name_parts[0]
            attrs['last_name'] = name_parts[1] if len(name_parts) > 1 else ''

        username = (attrs.get('username') or '').strip()
        if not username:
            base_username = attrs['email'].split('@', 1)[0]
            username = base_username
            suffix = 1
            while CustomUser.objects.filter(username=username).exists():
                suffix += 1
                username = f'{base_username}{suffix}'
            attrs['username'] = username

        attrs['role'] = attrs.get('role', CustomUser.Role.CITOYEN)
        return attrs

    def create(self, validated_data):#logique de création d'un nouvel utilisateur à partir des données validées, qui utilise la méthode create_user du modèle CustomUser pour s'assurer que le mot de passe est correctement haché et que les autres champs sont traités de manière appropriée lors de la création de l'instance d'utilisateur.
        return CustomUser.objects.create_user(**validated_data)


# Serializers pour les opérations de réinitialisation de mot de passe, 
# qui gèrent la création de jetons de réinitialisation et la validation des jetons lors de la confirmation de la réinitialisation.
class ForgotPasswordRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()

    def create_reset_token(self):#logique pour créer un jeton de réinitialisation de mot de passe à partir de l'email fourni, qui vérifie d'abord que l'email correspond à un utilisateur actif existant, puis utilise le signataire RESET_PASSWORD_SIGNER pour créer un jeton sécurisé contenant l'identifiant de l'utilisateur.
        email = self.validated_data['email'].strip().lower()
        try:
            user = CustomUser.objects.get(email=email, is_active=True)
        except CustomUser.DoesNotExist:
            return None
        return RESET_PASSWORD_SIGNER.sign(str(user.pk))


# Serializer pour la confirmation de la réinitialisation de mot de passe
class ForgotPasswordConfirmSerializer(serializers.Serializer):
    token = serializers.CharField()
    new_password = serializers.CharField(write_only=True, validators=[validate_password])

    def validate_token(self, value):
        try:
            user_id = RESET_PASSWORD_SIGNER.unsign(value, max_age=900)
        except SignatureExpired as exc:
            raise serializers.ValidationError('Le lien de reinitialisation a expire.') from exc
        except BadSignature as exc:
            raise serializers.ValidationError('Le jeton de reinitialisation est invalide.') from exc

        try:
            self.user = CustomUser.objects.get(pk=user_id, is_active=True)
        except CustomUser.DoesNotExist as exc:
            raise serializers.ValidationError('Utilisateur introuvable pour cette demande.') from exc
        return value

    def save(self, **kwargs):
        self.user.set_password(self.validated_data['new_password'])
        self.user.save(update_fields=['password'])
        return self.user

# Un serializer personnalisé pour l'obtention de tokens JWT
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = CustomUser.EMAIL_FIELD

    def validate(self, attrs):
        data = super().validate(attrs)
        data['user'] = UserSerializer(self.user).data
        data['role'] = self.user.role
        return data
