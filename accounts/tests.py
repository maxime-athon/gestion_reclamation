from django.test import override_settings
from django.urls import reverse
from django.core import mail
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import CustomUser

# Les tests pour les fonctionnalités d'authentification, 
# de gestion de profil et de réinitialisation de mot de passe, 
# qui vérifient que les différentes opérations fonctionnent correctement, 
# que les jetons de réinitialisation sont générés et validés correctement, 
# et que les utilisateurs peuvent mettre à jour leurs profils et réinitialiser leurs mots de passe comme prévu. 
# Ces tests utilisent les vues et les serializers définis dans accounts/views.py et accounts/serializers.py 
# pour simuler les différentes interactions avec l'API et vérifier les résultats attendus.

@override_settings(PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'])
class AccountApiTests(APITestCase):
    def setUp(self):
        self.password = 'Password123!'
        self.user = CustomUser.objects.create_user(
            email='user@test.com',
            username='user',
            password=self.password,
            role=CustomUser.Role.CITOYEN,
            first_name='Jean',
            last_name='Koffi',
            telephone='90000000',
        )
        response = self.client.post(
            reverse('token_obtain'),
            {'email': self.user.email, 'password': self.password},
            format='json',
        )
        self.token = response.data['access']

    def test_profile_patch_updates_current_user(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.patch(
            reverse('profil'),
            {
                'first_name': 'Komi',
                'last_name': 'Mensah',
                'telephone': '91112233',
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.first_name, 'Komi')
        self.assertEqual(self.user.last_name, 'Mensah')
        self.assertEqual(self.user.telephone, '91112233')

    def test_forgot_password_flow_allows_reset(self):
        request_response = self.client.post(
            reverse('forgot_password_request'),
            {'email': self.user.email},
            format='json',
        )
        self.assertEqual(request_response.status_code, status.HTTP_200_OK)
        
        # On vérifie que l'email a été envoyé au lieu de chercher dans la réponse JSON
        self.assertEqual(len(mail.outbox), 1)
        email_body = mail.outbox[0].body
        token = email_body.split(' : ')[1].split()[0]

        confirm_response = self.client.post(
            reverse('forgot_password_confirm'),
            {'token': token, 'new_password': 'NewPassword123!'},
            format='json',
        )
        self.assertEqual(confirm_response.status_code, status.HTTP_200_OK)

        login_response = self.client.post(
            reverse('token_obtain'),
            {'email': self.user.email, 'password': 'NewPassword123!'},
            format='json',
        )
        self.assertEqual(login_response.status_code, status.HTTP_200_OK)
