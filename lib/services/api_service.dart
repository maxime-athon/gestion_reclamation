/// ApiService
/// Couche générique de communication HTTP entre Flutter et le backend Django.
/// Gère les requêtes GET, POST, PUT, DELETE et ajoute automatiquement les headers nécessaires.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_error.dart';

class ApiService {
  static const String baseUrl = "https://gestion-reclamation-eim6.onrender.com/api";

  /// Récupère le token JWT stocké localement
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  /// Construit les headers HTTP avec ou sans token
  Map<String, String> _headers(String? token) {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  /// Requête GET
  Future<dynamic> get(String endpoint) async {
    final token = await _getToken();
    final response = await http.get(Uri.parse("$baseUrl/$endpoint"), headers: _headers(token));
    return _handleResponse(response);
  }

/// Requête POST 
Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool useToken = true}) async { // Changé en true
  final token = useToken ? await _getToken() : null;
  final response = await http.post(
    Uri.parse("$baseUrl/$endpoint"),
    headers: _headers(token), 
    body: jsonEncode(data)
  );
  return _handleResponse(response);
}


  /// Requête PUT
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.put(Uri.parse("$baseUrl/$endpoint"),
        headers: _headers(token), body: jsonEncode(data));
    return _handleResponse(response);
  }

  /// Requête PATCH
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.patch(Uri.parse("$baseUrl/$endpoint"),
        headers: _headers(token), body: jsonEncode(data));
    return _handleResponse(response);
  }

  /// Requête DELETE
  Future<dynamic> delete(String endpoint) async {
    final token = await _getToken();
    final response = await http.delete(Uri.parse("$baseUrl/$endpoint"), headers: _headers(token));
    return _handleResponse(response);
  }

  /// Gestion des réponses HTTP
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    }

    throw AppError(
      message: _extractErrorMessage(response),
      statusCode: response.statusCode,
      raw: response.body,
    );
  }

  String _extractErrorMessage(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      return _fallbackMessage(response.statusCode);
    }

    if (body is Map<String, dynamic>) {
      final directMessage = _pickDirectMessage(body);
      if (directMessage != null) {
        return directMessage;
      }

      final fieldErrors = <String>[];
      body.forEach((key, value) {
        if (key == 'non_field_errors') {
          fieldErrors.add(_normalizeValue(value));
        } else {
          final normalized = _normalizeValue(value);
          if (normalized.isNotEmpty) {
            fieldErrors.add('${_beautifyFieldName(key)}: $normalized');
          }
        }
      });

      if (fieldErrors.isNotEmpty) {
        return fieldErrors.join('\n');
      }
    }

    if (body is List && body.isNotEmpty) {
      return body.map((item) => item.toString()).join('\n');
    }

    return _fallbackMessage(response.statusCode);
  }

  String? _pickDirectMessage(Map<String, dynamic> body) {
    const keys = ['erreur', 'error', 'detail', 'message'];
    for (final key in keys) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String _normalizeValue(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).join(', ');
    }
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  String _beautifyFieldName(String field) {
    const labels = {
      'email': 'Email',
      'password': 'Mot de passe',
      'username': 'Nom complet',
      'phone': 'Téléphone',
      'telephone': 'Téléphone',
      'first_name': 'Prénom',
      'last_name': 'Nom',
    };

    return labels[field] ?? field.replaceAll('_', ' ');
  }

  String _fallbackMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Certaines informations sont invalides. Vérifiez le formulaire.';
      case 401:
        return 'Connexion refusée. Vérifiez vos identifiants.';
      case 403:
        return 'Vous n\'avez pas l\'autorisation pour cette action.';
      case 404:
        return 'La ressource demandée est introuvable.';
      case 500:
        return 'Le serveur rencontre un problème. Réessayez dans un instant.';
      default:
        return 'Une erreur est survenue. Merci de réessayer.';
    }
  }
}
