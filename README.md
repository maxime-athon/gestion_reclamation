# Application de Gestion des Réclamations (Flutter)

Cette application Flutter est une solution complète pour la gestion des réclamations et des tickets, conçue pour faciliter la communication et le suivi des incidents, des demandes et des réclamations entre les utilisateurs, les techniciens et les administrateurs. Elle offre une interface intuitive et des fonctionnalités robustes pour optimiser le processus de support.

## Fonctionnalités Clés

*   **Authentification Sécurisée:**
    *   Inscription et connexion des utilisateurs.
    *   Réinitialisation de mot de passe (demande et confirmation via token).
*   **Gestion Complète des Tickets:**
    *   Création de nouveaux tickets par les utilisateurs.
    *   Visualisation détaillée des tickets avec historique des commentaires.
    *   Filtrage des tickets par statut (Ouvert, En cours, Résolu, Clos) et par type (Incident, Réclamation, Demande).
    *   Mise à jour du statut des tickets par les techniciens et administrateurs.
    *   Assignation de tickets aux techniciens par les administrateurs.
    *   Ajout de commentaires aux tickets pour une communication fluide.
    *   Suppression et archivage des tickets (fonctionnalités administrateur).
*   **Système de Rôles:**
    *   **Utilisateur:** Crée et suit ses propres tickets, interagit via les commentaires.
    *   **Technicien:** Gère les tickets qui lui sont assignés, met à jour leur statut, et communique avec les utilisateurs.
    *   **Administrateur:** Accède à un tableau de bord complet pour la supervision, la gestion des tickets, la gestion des techniciens (ajout, activation/désactivation), et la consultation de statistiques détaillées.
*   **Notifications en Temps Réel:**
    *   Les utilisateurs reçoivent des notifications pour les mises à jour de leurs tickets.
    *   Possibilité de marquer les notifications comme lues individuellement ou en masse.
*   **Interface Utilisateur Intuitive et Responsive:**
    *   Design moderne et épuré.
    *   Adaptation à différentes tailles d'écran (mobile, tablette, desktop) pour le tableau de bord administrateur.
    *   Utilisation de `Provider` pour une gestion d'état efficace.

## Technologies Utilisées

*   **Frontend:**
    *   **Flutter (Dart):** Framework UI pour le développement multiplateforme.
    *   **Provider:** Pour la gestion de l'état de l'application.
    *   **http:** Pour les requêtes HTTP vers l'API.
    *   **shared_preferences:** Pour la persistance des données locales (ex: token d'authentification).
    *   **intl:** Pour la localisation et le formatage des dates.
*   **Backend (API):**
    *   **Django REST Framework (DRF):** (Implicite, basé sur les endpoints et la structure des services).

## Installation et Lancement

Pour lancer ce projet en local, suivez les étapes ci-dessous.

### Prérequis

*   Flutter SDK installé (version compatible avec `sdk: ^3.9.2`).
*   Un environnement de développement configuré (VS Code, Android Studio).
*   Un backend API compatible (Django REST Framework est implicite) doit être en cours d'exécution et accessible. Assurez-vous que l'URL de votre API est correctement configurée dans `lib/services/api_service.dart`.

### Étapes

1.  **Cloner le dépôt:**
    ```bash
    git clone [URL_DE_VOTRE_DEPOT]
    cd reclamations_app
    ```
2.  **Installer les dépendances Flutter:**
    ```bash
    flutter pub get
    ```
3.  **Lancer l'application:**
    ```bash
    flutter run
    ```
    Ou pour un build de production (APK pour Android):
    ```bash
    flutter build apk --release
    ```

## Aperçu de l'Interface (Captures d'écran)

Voici quelques aperçus de l'application en action.

<!-- Insérez ici vos images d'interface. Exemples: -->
### Vue d'accueil
[ecran connexion](/assets/img/ecrans_de_conexion.png)

### Vue des tickets
[ecran tickets](/assets/img/liste_des_tickets.png)

### Detail d'un ticket
[ecran detail ticket](/assets/img/detail_ticket.png)

### Vue des techniciens
[ecran techniciens](/assets/img/ecrans_technitien.png)

### Vue adminstrateur
[ecran admin](/assets/img/ecrans_admin.png)




## Télécharger l'APK

Vous pouvez télécharger la dernière version de l'application Android (APK) pour la tester directement sur votre appareil.

**https://drive.google.com/file/d/15bvtOMIhGiNzFTFkgJQ4nF5daaaQiXxo/view?usp=drive_link**

