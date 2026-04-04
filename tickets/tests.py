from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import CustomUser
from tickets.models import HistoriqueStatut, Notification, Ticket

# Les tests pour les fonctionnalités d'authentification, 
# de gestion de profil et de réinitialisation de mot de passe, 
# qui vérifient que les différentes opérations fonctionnent correctement, 
# que les jetons de réinitialisation sont générés et validés correctement, 
# et que les utilisateurs peuvent mettre à jour leurs profils et réinitialiser leurs mots de passe comme prévu. 
# Ces tests utilisent les vues et les serializers définis dans accounts/views.py et accounts/serializers.py pour simuler les différentes interactions avec l'API et vérifier les résultats attendus.  
# Les tests d'intégration pour les fonctionnalités de gestion des tickets, qui vérifient que les différentes opérations liées aux tickets (création, modification, assignation, commentaires, notifications) fonctionnent correctement et que les règles de permission sont respectées. 
# Ces tests simulent des interactions complètes avec l'API, en utilisant différents rôles d'utilisateur (citoyen, technicien, administrateur) pour vérifier que les fonctionnalités sont accessibles et fonctionnent comme prévu pour chaque type d'utilisateur.
# Les tests d'intégration couvrent des scénarios tels que la création de tickets par les citoyens, l'assignation de tickets par les administrateurs, la modification du statut des tickets par les techniciens, l'ajout de commentaires et la réception de notifications, ainsi que les restrictions d'accès basées sur les rôles des utilisateurs.
  

@override_settings(PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'])
class IntegrationTests(APITestCase):
    def setUp(self):
        self.password = 'Password123!'
        self.citoyen = CustomUser.objects.create_user(
            email='citoyen@test.com',
            username='citoyen',
            password=self.password,
            role=CustomUser.Role.CITOYEN,
            first_name='Jean',
            last_name='Koffi',
        )
        self.tech = CustomUser.objects.create_user(
            email='tech@test.com',
            username='tech',
            password=self.password,
            role=CustomUser.Role.TECHNICIEN,
            first_name='Marc',
            last_name='Issa',
        )
        self.admin = CustomUser.objects.create_user(
            email='admin@test.com',
            username='admin',
            password=self.password,
            role=CustomUser.Role.ADMIN,
            first_name='Ada',
            last_name='Admin',
        )

        self.token_citoyen = self._get_token(self.citoyen.email, self.password)
        self.token_tech = self._get_token(self.tech.email, self.password)
        self.token_admin = self._get_token(self.admin.email, self.password)

    def _get_token(self, email, password):
        response = self.client.post(
            reverse('token_obtain'),
            {'email': email, 'password': password},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        return response.data['access']

    def _ticket_payload(self, **overrides):
        payload = {
            'titre': 'Panne eclairage amphi',
            'description': 'La moitie de l amphi est sans lumiere depuis ce matin.',
            'type_ticket': 'INCIDENT',
            'priorite': 'HAUTE',
        }
        payload.update(overrides)
        return payload

    def _create_ticket(self, auteur=None, **overrides):
        auteur = auteur or self.citoyen
        data = self._ticket_payload(**overrides)
        return Ticket.objects.create(
            titre=data['titre'],
            description=data['description'],
            type_ticket=data['type_ticket'],
            priorite=data['priorite'],
            auteur=auteur,
            statut=overrides.get('statut', Ticket.Statut.OUVERT),
            assigne_a=overrides.get('assigne_a'),
            est_archive=overrides.get('est_archive', False),
        )

    def test_authentication_returns_role_and_user(self):
        response = self.client.post(
            reverse('token_obtain'),
            {'email': self.tech.email, 'password': self.password},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['role'], CustomUser.Role.TECHNICIEN)
        self.assertEqual(response.data['user']['email'], self.tech.email)

    def test_citoyen_can_create_ticket(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_citoyen}')
        response = self.client.post(reverse('ticket-list'), self._ticket_payload(), format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['auteur']['email'], self.citoyen.email)
        self.assertTrue(Notification.objects.filter(destinataire=self.admin, ticket_id=response.data['id']).exists())

    def test_citoyen_only_sees_own_tickets(self):
        own_ticket = self._create_ticket(auteur=self.citoyen)
        self._create_ticket(auteur=self.admin, titre='Ticket admin', description='Description admin suffisamment longue.')

        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_citoyen}')
        response = self.client.get(reverse('ticket-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        returned_ids = [item['id'] for item in response.data['results']]
        self.assertEqual(returned_ids, [own_ticket.id])

    def test_technicien_assigned_filter_only_returns_his_tickets(self):
        my_ticket = self._create_ticket(assigne_a=self.tech, statut=Ticket.Statut.EN_COURS)
        self._create_ticket()

        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_tech}')
        response = self.client.get(f"{reverse('ticket-list')}?assigned=true")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual([item['id'] for item in response.data['results']], [my_ticket.id])

    def test_assigned_technicien_can_change_status(self):
        ticket = self._create_ticket(assigne_a=self.tech, statut=Ticket.Statut.EN_COURS)

        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_tech}')
        response = self.client.patch(
            reverse('ticket-changer-statut', args=[ticket.id]),
            {'statut': Ticket.Statut.RESOLU},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['statut'], Ticket.Statut.RESOLU)
        self.assertTrue(HistoriqueStatut.objects.filter(ticket=ticket, nouveau_statut=Ticket.Statut.RESOLU).exists())
        self.assertTrue(Notification.objects.filter(destinataire=self.citoyen, ticket=ticket, titre='Mise a jour de votre ticket').exists())

    def test_citoyen_cannot_change_status(self):
        ticket = self._create_ticket()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_citoyen}')
        response = self.client.patch(
            reverse('ticket-changer-statut', args=[ticket.id]),
            {'statut': Ticket.Statut.EN_COURS},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_can_assign_ticket(self):
        ticket = self._create_ticket()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_admin}')
        response = self.client.patch(
            reverse('ticket-assigner', args=[ticket.id]),
            {'technicien_id': self.tech.id},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['assigne_a']['id'], self.tech.id)
        self.assertEqual(response.data['statut'], Ticket.Statut.EN_COURS)

    def test_admin_can_toggle_technician_active_status(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_admin}')
        response = self.client.patch(
            reverse('user-toggle-active', args=[self.tech.id]),
            {'is_active': False},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.tech.refresh_from_db()
        self.assertFalse(self.tech.is_active)

    def test_statistiques_admin_only(self):
        self._create_ticket(priorite=Ticket.Priorite.CRITIQUE)
        url = reverse('ticket-statistiques')

        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_citoyen}')
        self.assertEqual(self.client.get(url).status_code, status.HTTP_403_FORBIDDEN)

        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_admin}')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('critical_tickets', response.data)
        self.assertIn('par_type', response.data)

    def test_archiver_requires_resolved_or_closed_ticket(self):
        ticket = self._create_ticket(statut=Ticket.Statut.OUVERT)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_admin}')

        response = self.client.post(reverse('ticket-archiver', args=[ticket.id]))
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        ticket.statut = Ticket.Statut.CLOS
        ticket.save(update_fields=['statut'])
        response = self.client.post(reverse('ticket-archiver', args=[ticket.id]))
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_invalid_status_is_rejected(self):
        ticket = self._create_ticket(assigne_a=self.tech, statut=Ticket.Statut.EN_COURS)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_tech}')
        response = self.client.patch(
            reverse('ticket-changer-statut', args=[ticket.id]),
            {'statut': 'NON_EXISTANT'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('erreur', response.data)

    def test_empty_comment_is_rejected(self):
        ticket = self._create_ticket()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_citoyen}')
        response = self.client.post(
            reverse('ticket-commenter', args=[ticket.id]),
            {'contenu': '   '},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('contenu', response.data)

    def test_notifications_can_be_listed_and_marked_as_read(self):
        notification = Notification.objects.create(
            destinataire=self.tech,
            titre='Nouveau ticket assigne',
            message='Le ticket #1 vous a ete attribue.',
        )
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_tech}')

        list_response = self.client.get(reverse('notification-list'))
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(list_response.data['results'][0]['id'], notification.id)

        patch_response = self.client.patch(
            reverse('notification-detail', args=[notification.id]),
            {'est_lue': True},
            format='json',
        )
        self.assertEqual(patch_response.status_code, status.HTTP_200_OK)
        notification.refresh_from_db()
        self.assertTrue(notification.est_lue)

    def test_public_register_cannot_create_technicien(self):
        response = self.client.post(
            reverse('register'),
            {
                'email': 'new-tech@test.com',
                'password': 'Password123!',
                'full_name': 'New Tech',
                'role': CustomUser.Role.TECHNICIEN,
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('role', response.data)

    def test_profile_endpoint_returns_current_user(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_tech}')
        response = self.client.get(reverse('profil'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['email'], self.tech.email)

    def test_string_representations_are_stable(self):
        ticket = self._create_ticket()
        self.assertEqual(str(ticket), f'#{ticket.id} - [{ticket.statut}] {ticket.titre}')
        self.assertEqual(str(self.citoyen), 'Jean Koffi (CITOYEN)')
