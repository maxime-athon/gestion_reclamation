from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from accounts.models import CustomUser
from tickets.models import Ticket, HistoriqueStatut


class IntegrationTests(APITestCase):
    """
    Tests d'intégration pour valider la Phase 4 :
    - Authentification JWT
    - Création de ticket
    - Liste avec filtres
    - Changement de statut
    - Vérification des privilèges
    - Expiration du token
    """

    def setUp(self):
        # Création des utilisateurs
        self.citoyen = CustomUser.objects.create_user(
            email="citoyen@test.com", username="citoyen", password="1234", role="CITOYEN"
        )
        self.tech = CustomUser.objects.create_user(
            email="tech@test.com", username="tech", password="1234", role="TECHNICIEN"
        )
        self.admin = CustomUser.objects.create_user(
            email="admin@test.com", username="admin", password="1234", role="ADMIN"
        )

        # Authentification citoyen
        url = reverse('token_obtain')
        response = self.client.post(url, {"email": "citoyen@test.com", "password": "1234"}, format='json')
        self.token_citoyen = response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_citoyen}')

    def test_1_authentication(self):
        """Test 1 : Authentification JWT et header Authorization"""
        url = reverse('ticket-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_2_creation_ticket(self):
        """Test 2 : Création de ticket par citoyen"""
        url = reverse('ticket-list')
        data = {"titre": "Ticket Test", "description": "Problème test"}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['auteur']['email'], "citoyen@test.com")

    def test_3_liste_tickets_filtre(self):
        """Test 3 : Liste des tickets avec filtre par statut"""
        Ticket.objects.create(titre="Ticket 1", description="Desc", auteur=self.citoyen, statut="OUVERT")
        url = reverse('ticket-list') + "?statut=OUVERT"
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(all(t['statut'] == "OUVERT" for t in response.data['results']))

    def test_4_changement_statut(self):
        """Test 4 : Changement de statut par technicien"""
        ticket = Ticket.objects.create(titre="Ticket 2", description="Desc", auteur=self.citoyen)
        # Authentification technicien
        url = reverse('token_obtain')
        response = self.client.post(url, {"email": "tech@test.com", "password": "1234"}, format='json')
        token_tech = response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token_tech}')
        # Changer statut
        url = reverse('ticket-changer-statut', args=[ticket.id])
        response = self.client.patch(url, {"statut": "EN_COURS"}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['statut'], "EN_COURS")
        self.assertTrue(HistoriqueStatut.objects.filter(ticket=ticket).exists())

    def test_5_privileges(self):
        """Test 5 : Citoyen ne peut pas changer le statut"""
        ticket = Ticket.objects.create(titre="Ticket 3", description="Desc", auteur=self.citoyen)
        url = reverse('ticket-changer-statut', args=[ticket.id])
        # Citoyen essaie de changer le statut
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token_citoyen}')
        response = self.client.patch(url, {"statut": "EN_COURS"}, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_6_token_expire(self):
        """Test 6 : Token expiré (simulation)"""
        # On supprime volontairement le token pour simuler expiration
        self.client.credentials(HTTP_AUTHORIZATION="Bearer expired_token")
        url = reverse('ticket-list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)