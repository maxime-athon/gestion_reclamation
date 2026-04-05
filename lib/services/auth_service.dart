/// AuthService
/// Service Flutter pour gérer l’authentification via l’API Django REST.
/// Respecte les endpoints définis :
/// - POST /api/auth/login/     → login()
/// - POST /api/auth/refresh/   → refreshToken()
/// - POST /api/auth/register/  → register()
/// - logout()                  → suppression des tokens locaux
/// - isLoggedIn()              → vérifie si un token est présent
/// - fetchProfile()            → récupère les infos du profil connecté
/// - updateProfile()           → met à jour les infos du profil connecté
/// - restoreSession()          → restaure la session à partir des tokens stockés
/// - getCachedUser()           → récupère les infos de l'utilisateur depuis le cache local
/// - getCachedRole()           → récupère le rôle de l'utilisateur depuis le cache local 
/// Utilise SharedPreferences pour stocker les tokens JWT, le rôle de l'utilisateur, et les informations de profil localement, permettant une expérience utilisateur fluide avec une gestion efficace de la session et des données d'authentification. Le service gère également les erreurs de manière centralisée, offrant des messages d'erreur clairs en cas de problèmes de connexion ou de communication avec l'API

import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_error.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Service Flutter pour gérer l’authentification via l’API Django REST.
/// Gère le stockage local des tokens, du profil et du rôle utilisateur.
class AuthService {
  final ApiService _api = ApiService();
  
  // Clés pour SharedPreferences
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userRoleKey = 'user_role';
  static const _userProfileKey = 'user_profile';

  /// Connexion utilisateur : Récupère les tokens et les infos de profil
  Future<Map<String, dynamic>> login(String identifiant, String password) async {
    try {
      final data = await _api.post("auth/login/", {
        "email": identifiant,
        "password": password,
      }, useToken: false);

      final prefs = await SharedPreferences.getInstance();
      
      // Stockage des tokens JWT
      if (data.containsKey("access")) {
        await prefs.setString(_accessTokenKey, data["access"]);
      }
      if (data.containsKey("refresh")) {
        await prefs.setString(_refreshTokenKey, data["refresh"]);
      }

      // Extraction ou récupération du profil utilisateur
      AppUser? user;
      if (data['user'] is Map<String, dynamic>) {
        user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        user = await fetchProfile();
      }

      // Mise en cache du rôle et du profil complet
      await prefs.setString(_userRoleKey, user.role);
      await prefs.setString(_userProfileKey, user.toStorage());

      return {
        "success": true,
        "role": user.role,
        "user": user,
      };
    } on AppError catch (e) {
      return {"success": false, "message": e.message};
    } catch (e) {
      return {
        "success": false,
        "message": "Impossible de se connecter pour le moment. Réessayez.",
      };
    }
  }

  /// Renouveler l’access token en utilisant le refresh token stocké
  Future<void> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString(_refreshTokenKey);
    if (refresh != null) {
      final data = await _api.post("auth/refresh/", {"refresh": refresh}, useToken: false);
      if (data.containsKey("access")) {
        await prefs.setString(_accessTokenKey, data["access"]);
      }
    }
  }

  /// Créer un nouveau compte utilisateur
  Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData, {
    bool useToken = false,
  }) async {
    final data = await _api.post("auth/register/", userData, useToken: useToken);
    return data;
  }


/// Créer un technicien (via le ViewSet Admin pour déclencher l'email)
Future<Map<String, dynamic>> adminCreateUser(Map<String, dynamic> userData) async {
  try {
    final data = await _api.post("users/", userData, useToken: true);
    
    return {
      "success": true, 
      "data": data
    };
  } on AppError catch (e) {
    return {"success": false, "message": e.message};
  } catch (e) {
    return {"success": false, "message": "Erreur lors de la création du technicien."};
  }
}

  /// Déconnexion : Nettoyage complet de SharedPreferences
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
  }

  /// Vérifie simplement si un access token est présent localement
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey) != null;
  }

  /// Récupère les informations du profil depuis le serveur et met à jour le cache
  Future<AppUser> fetchProfile() async {
    final data = await _api.get("auth/profil/");
    final user = AppUser.fromJson(data as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, user.role);
    await prefs.setString(_userProfileKey, user.toStorage());
    return user;
  }

  /// Met à jour les informations du profil utilisateur
  Future<AppUser> updateProfile(Map<String, dynamic> payload) async {
    final data = await _api.patch("auth/profil/", payload);
    final user = AppUser.fromJson(data as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, user.role);
    await prefs.setString(_userProfileKey, user.toStorage());
    return user;
  }

  /// Récupère l'utilisateur depuis le stockage local (expérience fluide offline)
  Future<AppUser?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUser.fromStorage(raw);
    } catch (_) {
      return null;
    }
  }

  /// Récupère le rôle en cache (ADMIN, TECHNICIEN, CITOYEN)
  Future<String?> getCachedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  /// Restaure la session au démarrage de l'application
  Future<Map<String, dynamic>> restoreSession() async {
    final loggedIn = await isLoggedIn();
    if (!loggedIn) {
      return {'isLoggedIn': false, 'role': null, 'user': null};
    }

    final cachedUser = await getCachedUser();
    if (cachedUser != null) {
      return {
        'isLoggedIn': true,
        'role': cachedUser.role,
        'user': cachedUser,
      };
    }

    try {
      final user = await fetchProfile();
      return {
        'isLoggedIn': true,
        'role': user.role,
        'user': user,
      };
    } on AppError {
      await logout();
      rethrow;
    }
  }

  /// Demander une réinitialisation de mot de passe (envoi d'email via Django)
  Future<Map<String, dynamic>> forgotPasswordRequest(String email) async {
    try {
      final data = await _api.post("auth/forgot-password/", {
        "email": email,
      }, useToken: false);
      return {"success": true, "message": data["message"] ?? "Email de réinitialisation envoyé."};
    } on AppError catch (e) {
      return {"success": false, "message": e.message};
    } catch (e) {
      return {"success": false, "message": "Erreur lors de l'envoi de l'email."};
    }
  }

  /// Valider le nouveau mot de passe avec le jeton reçu
  Future<Map<String, dynamic>> forgotPasswordConfirm(String token, String newPassword) async {
    try {
      final data = await _api.post("auth/reset-password/", {
        "token": token,
        "new_password": newPassword,
      }, useToken: false);
      return {"success": true, "message": data["message"] ?? "Mot de passe modifié avec succès."};
    } on AppError catch (e) {
      return {"success": false, "message": e.message};
    } catch (e) {
      return {"success": false, "message": "Erreur lors de la modification du mot de passe."};
    }
  }
}


