/// TicketService
/// Service Flutter pour consommer l’API Django REST.
/// Respecte les endpoints définis dans TicketViewSet :
/// - GET    /api/tickets/                  → listerTickets()
/// - POST   /api/tickets/                  → creerTicket()
/// - GET    /api/tickets/{id}/             → getTicket()
/// - PATCH  /api/tickets/{id}/changer_statut/ → changerStatut()
/// - POST   /api/tickets/{id}/commenter/   → commenterTicket()
/// - PATCH  /api/tickets/{id}/assigner/    → assignerTicket()
/// - DELETE /api/tickets/{id}/             → supprimerTicket()

import '../models/ticket.dart';
import 'api_service.dart';

class TicketService {
  final ApiService _api = ApiService();

  /// Liste tous les tickets visibles pour l’utilisateur connecté
  Future<List<Ticket>> listerTickets({String? statut, bool assignedToMe = false}) async {
    String endpoint = "tickets/";
    List<String> params = [];
    if (statut != null) params.add("statut=$statut");
    if (assignedToMe) params.add("assigned=true");
    
    if (params.isNotEmpty) endpoint += "?" + params.join("&");

    final data = await _api.get(endpoint);
    
    // Gestion de la pagination Django (format { "results": [...] })
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      return (data['results'] as List).map((json) => Ticket.fromJson(json)).toList();
    }

    return (data as List).map((json) => Ticket.fromJson(json)).toList();
  }

  /// Récupère le détail d’un ticket par son ID
  Future<Ticket> getTicket(int id) async {
    final data = await _api.get("tickets/$id/");
    return Ticket.fromJson(data);
  }

  /// Crée un nouveau ticket
  Future<Ticket> creerTicket(Map<String, dynamic> ticketData) async {
    final data = await _api.post("tickets/", ticketData, useToken: true);
    return Ticket.fromJson(data);
  }

  /// Change le statut d’un ticket (PATCH /changer_statut/)
  Future<Ticket> changerStatut(int id, String nouveauStatut) async {
    final data = await _api.patch("tickets/$id/changer_statut/", {"statut": nouveauStatut});
    return Ticket.fromJson(data);
  }

  /// Ajoute un commentaire à un ticket (POST /commenter/)
  Future<void> commenterTicket(int id, String contenu) async {
    await _api.post("tickets/$id/commenter/", {"contenu": contenu}, useToken: true);
  }

  /// Assigne un ticket à un technicien (PATCH /assigner/)
  Future<Ticket> assignerTicket(int id, int technicienId) async {
    final data = await _api.patch("tickets/$id/assigner/", {"technicien_id": technicienId});
    return Ticket.fromJson(data);
  }

  /// Supprime un ticket
  Future<void> supprimerTicket(int id) async {
    await _api.delete("tickets/$id/");
  }

  /// Récupère les statistiques (Admin)
  Future<Map<String, dynamic>> getStats() async {
    return await _api.get("tickets/statistiques/");
  }

  /// Archive un ticket spécifique (Admin)
  Future<void> archiverTicket(int id) async {
    await _api.post("tickets/$id/archiver/", {});
  }

  /// Récupère la liste des techniciens pour l'assignation
  Future<List<Map<String, dynamic>>> getTechniciens() async {
    final data = await _api.get("users/?role=TECHNICIEN");
    
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      return List<Map<String, dynamic>>.from(data['results']);
    }
    return List<Map<String, dynamic>>.from(data);
  }

/// Récupère les notifications de l'utilisateur connecté
Future<dynamic> getNotifications() async {
  // L'URL générée par le router pour NotificationViewSet est "notifications/"
  return await _api.get("notifications/");
}

Future<void> marquerLue(int id) async {
  // Action personnalisée @action(detail=True) -> notifications/{id}/mark_as_read/
  await _api.post("notifications/$id/mark_as_read/", {});
}

Future<void> marquerToutesLues() async {
  // Action personnalisée @action(detail=False) -> notifications/mark_all_read/
  await _api.post("notifications/mark_all_read/", {});
}

  Future<Map<String, dynamic>> updateUserStatus(int id, bool isActive) async {
    final data = await _api.patch("users/$id/toggle-active/", {"is_active": isActive});
    return Map<String, dynamic>.from(data);
  }
}

/// admin vois les statistique 

//configure les type et les priorite

///archiver le ticket clos

//
