/// TicketProvider
/// Provider Flutter qui gère l’état global des tickets.
/// Utilise TicketService pour communiquer avec l’API.
/// Permet de :
/// - Charger la liste des tickets
/// - Consulter le détail d’un ticket
/// - Créer un ticket
/// - Changer le statut
/// - Assigner un ticket
/// - Ajouter un commentaire
/// - Supprimer un ticket
/// - Voirs les statistique
/// - archiver les ficher clos
/// - Charger la liste des techniciens
/// - Charger les notifications
/// - Marquer une notification comme lue
/// - Marquer toutes les notifications comme lues
/// - Mettre a jour le statut d’un technicien (Actif/Inactif)


import 'package:flutter/material.dart';

import '../core/app_error.dart';
import '../models/app_notification.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  final TicketService _ticketService = TicketService();

  List<Ticket> _tickets = [];
  List<AppNotification> _notifications = [];
  Ticket? _selectedTicket;
  List<Map<String, dynamic>> _technicians = [];
  Map<String, dynamic> _stats = {};
  bool _loading = false;
  bool _notificationsLoading = false;
  String? _error;
  String? _notificationError;

  List<Ticket> get tickets => _tickets;
  List<AppNotification> get notifications => _notifications;
  Ticket? get selectedTicket => _selectedTicket;
  List<Map<String, dynamic>> get technicians => _technicians;
  Map<String, dynamic> get stats => _stats;
  bool get loading => _loading;
  bool get notificationsLoading => _notificationsLoading;
  String? get error => _error;
  String? get notificationError => _notificationError;
  int get unreadNotificationsCount =>
      _notifications.where((notification) => !notification.isRead).length;

  void _replaceTicketInCollections(Ticket updated) {
    _tickets = _tickets.map((ticket) => ticket.id == updated.id ? updated : ticket).toList();
    if (_selectedTicket?.id == updated.id) {
      _selectedTicket = updated;
    }
  }

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  /// Charge tous les tickets
  Future<void> fetchTickets({String? statut, bool assignedToMe = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _tickets = await _ticketService.listerTickets(statut: statut, assignedToMe: assignedToMe);
    } on AppError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Impossible de charger les tickets pour le moment.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Charge le détail d’un ticket
  Future<void> fetchTicketDetail(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTicket = await _ticketService.getTicket(id);
    } on AppError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Impossible de charger le détail du ticket.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Crée un nouveau ticket
  Future<void> addTicket(Map<String, dynamic> data) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final newTicket = await _ticketService.creerTicket(data);
      _tickets.add(newTicket);
    } on AppError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'La création du ticket a échoué. Réessayez.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Change le statut d’un ticket
  Future<void> updateStatut(int id, String statut) async {
    try {
      final updated = await _ticketService.changerStatut(id, statut);
      _replaceTicketInCollections(updated);
      notifyListeners();
    } on AppError catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'Le statut du ticket n\'a pas pu être mis à jour.';
      notifyListeners();
    }
  }

  /// Assigne un ticket à un technicien
  Future<void> assignTicket(int id, int technicienId) async {
    try {
      final updated = await _ticketService.assignerTicket(id, technicienId);
      _replaceTicketInCollections(updated);
      notifyListeners();
    } on AppError catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'L\'assignation du ticket a échoué.';
      notifyListeners();
    }
  }

  /// Ajoute un commentaire à un ticket
  Future<void> addComment(int id, String contenu) async {
    try {
      await _ticketService.commenterTicket(id, contenu);
      await fetchTicketDetail(id); // recharge le ticket pour voir le commentaire
    } on AppError catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'Le commentaire n\'a pas pu être envoyé.';
      notifyListeners();
    }
  }

  /// Supprime un ticket
  Future<void> deleteTicket(int id) async {
    try {
      await _ticketService.supprimerTicket(id);
      _tickets.removeWhere((t) => t.id == id);
      notifyListeners();
    } on AppError catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'La suppression du ticket a échoué.';
      notifyListeners();
    }
  }

  /// Charge les statistiques
  Future<void> fetchStats() async {
    try {
      _stats = await _ticketService.getStats();
      notifyListeners();
    } on AppError catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'Impossible de charger les statistiques.';
      notifyListeners();
    }
  }

  /// Archive les tickets
  Future<void> archiveTicket(int id) async {
    try {
      await _ticketService.archiverTicket(id);
      _tickets.removeWhere((t) => t.id == id);
      notifyListeners();
    } on AppError catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'L\'archivage du ticket a échoué.';
      notifyListeners();
    }
  }

  /// Charge la liste des techniciens
  Future<void> fetchTechnicians() async {
    try {
      _technicians = await _ticketService.getTechniciens();
      notifyListeners();
    } on AppError catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'Impossible de charger la liste des techniciens.';
      notifyListeners();
    }
  }

    Future<void> fetchNotifications() async {
    _notificationsLoading = true;
    _notificationError = null; 
    notifyListeners();

    try {
      final dynamic data = await _ticketService.getNotifications();
      
      List<dynamic> rawData;
      // Gestion flexible du format
      if (data is List) {
        rawData = data;
      } else if (data is Map && data.containsKey('results')) {
        rawData = data['results'];
      } else {
        rawData = [];
      }

      // Conversion sécurisée
      _notifications = rawData.map((json) {
        return AppNotification.fromJson(json as Map<String, dynamic>);
      }).toList();
      
    } on AppError catch (e) {
      _notificationError = e.message;
    } catch (e) {
      print("DEBUG NOTIF ERROR: $e");
      _notificationError = 'Impossible de charger les notifications.';
    } finally {
      _notificationsLoading = false;
      notifyListeners();
    }
  }

  // --- MÉTHODES DE NOTIFICATIONS CORRIGÉES ---

  Future<void> markNotificationRead(int id) async {
    try {
      await _ticketService.marquerLue(id);
      
      // On reconstruit la liste en précisant le type <AppNotification>
      _notifications = _notifications.map<AppNotification>((n) {
        if (n.id == id) {
          // On crée une nouvelle instance manuellement puisque copyWith n'existe pas
          return AppNotification(
            id: n.id,
            title: n.title,
            message: n.message,
            isRead: true,
            createdAt: n.createdAt,
            type: n.type,
            ticketId: n.ticketId,
          );
        }
        return n;
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Non-critical error: Impossible de marquer la notification comme lue ($e)');
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _ticketService.marquerToutesLues();
      
      // On passe tout en "isRead: true" pour toute la liste
      _notifications = _notifications.map<AppNotification>((n) {
        return AppNotification(
          id: n.id,
          title: n.title,
          message: n.message,
          isRead: true,
          createdAt: n.createdAt,
          type: n.type,
          ticketId: n.ticketId,
        );
      }).toList();
      
      notifyListeners();
    } catch (e) {
      _notificationError = 'Impossible de marquer toutes les notifications comme lues';
      debugPrint('Notification Error: $e');
      notifyListeners();
    }
  }


  Future<void> updateTechnicianStatus(int id, bool isActive) async {
    try {
      final updatedUser = await _ticketService.updateUserStatus(id, isActive);
      _technicians = _technicians
          .map((tech) => tech['id'] == id ? updatedUser : tech)
          .toList();
      notifyListeners();
    } on AppError catch (e) {
      _error = e.message;
      notifyListeners();
    } catch (e) {
      _error = 'Impossible de mettre a jour le statut du technicien.';
      notifyListeners();
    }
  }
}
