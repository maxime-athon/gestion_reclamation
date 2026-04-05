/// AuthProvider
/// Provider Flutter qui gère l’état d’authentification.
/// Utilise AuthService pour communiquer avec l’API.
/// Permet de :
/// - Se connecter
/// - Se déconnecter
/// - Vérifier l’état de connexion
/// - Créer un compte
/// - Rafraîchir le token JWT
/// - Demander une réinitialisation de mot de passe
/// - Valider la réinitialisation de mot de passe avec un jeton reçu par email


import 'package:flutter/material.dart';

import '../core/app_error.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  String? _userRole; // 'ADMIN', 'TECHNICIEN', 'CITOYEN'
  AppUser? _currentUser;
  bool _loading = false;
  String? _error;

  bool get isLoggedIn => _isLoggedIn;
  String? get userRole => _userRole;
  AppUser? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  /// Connexion utilisateur
  Future<void> login(String identifiant, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(identifiant, password);
    if (result["success"] == true) {
      _isLoggedIn = true;
      _userRole = result["role"] as String?;
      _currentUser = result["user"] as AppUser?;
      _error = null;
    } else {
      _isLoggedIn = false;
      _userRole = null;
      _currentUser = null;
      _error = result["message"];
    }
    _loading = false;
    notifyListeners();
  }

  /// Déconnexion
  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _userRole = null;
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  /// Vérifie si l’utilisateur est connecté
  Future<void> checkLoginStatus() async {
    _loading = true;
    notifyListeners();

    try {
      final session = await _authService.restoreSession();
      _isLoggedIn = session['isLoggedIn'] == true;
      _userRole = session['role'] as String?;
      _currentUser = session['user'] as AppUser?;
      _error = null;
    } on AppError catch (e) {
      _isLoggedIn = false;
      _userRole = null;
      _currentUser = null;
      _error = e.message;
    } catch (_) {
      _isLoggedIn = false;
      _userRole = null;
      _currentUser = null;
      _error = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _authService.fetchProfile();
      _currentUser = user;
      _userRole = user.role;
      notifyListeners();
    } on AppError catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (_) {
      _error = 'Le profil n\'a pas pu etre recharge.';
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> payload) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.updateProfile(payload);
      _currentUser = user;
      _userRole = user.role;
      return true;
    } on AppError catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'La mise a jour du profil a echoue.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Création de compte
  Future<void> register(
    Map<String, dynamic> userData, {
    bool useToken = false,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(userData, useToken: useToken);
      _error = null;
    } on AppError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Inscription impossible pour le moment. Réessayez.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

/// Création d’un technicien par un admin
Future<bool> adminCreateUser(Map<String, dynamic> userData) async {
  _loading = true;
  _error = null;
  notifyListeners();

  final result = await _authService.adminCreateUser(userData);
  
  _loading = false;
  if (result["success"] == false) {
    _error = result["message"];
    notifyListeners();
    return false;
  }
  notifyListeners();
  return true;
}

  /// Rafraîchit le token JWT
  Future<void> refreshToken() async {
    try {
      await _authService.refreshToken();
    } on AppError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'La session n\'a pas pu être actualisée.';
    }
    notifyListeners();
  }

  /// Demande de réinitialisation de mot de passe
  Future<bool> forgotPasswordRequest(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.forgotPasswordRequest(email);
      if (result['success'] == true) {
        _error = null;
        return true;
      } else {
        _error = result['message'];
        return false;
      }
    } on AppError catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Impossible d\'envoyer la demande de reinitialisation.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Valider le nouveau mot de passe avec le jeton reçu par email
  Future<bool> forgotPasswordConfirm(String token, String newPassword) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.forgotPasswordConfirm(token, newPassword);
      if (result['success'] == true) {
        return true;
      } else {
        _error = result['message'];
        return false;
      }
    } on AppError catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'La réinitialisation a échoué.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

}
