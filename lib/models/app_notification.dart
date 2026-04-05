
//cet fichier contient le modele de notification de l'application
//il est utilisé pour stocker les notifications reçues par l'utilisateur et les afficher dans la section notifications de l'application
//le modèle de notification contient les informations suivantes :
//- id : l'identifiant unique de la notification
//- title : le titre de la notification
//- message : le message de la notification
//- isRead : un booléen indiquant si la notification a été lue ou non
//- createdAt : la date de création de la notification
//- type : le type de notification (ex: "INFO", "ALERT", etc.)
//- ticketId : l'identifiant du ticket associé à la notification (si applicable)

class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;
  final String type;
  final int? ticketId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.type,
    this.ticketId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      title: (json['titre'] ?? json['title'] ?? json['type_display'] ?? 'Notification')
          .toString(),
      message: (json['message'] ?? json['contenu'] ?? json['description'] ?? '')
          .toString(),
      isRead: json['est_lue'] == true || json['is_read'] == true,
      createdAt: (json['date_creation'] ?? json['created_at'] ?? '').toString(),
      type: (json['type'] ?? 'INFO').toString(),
      ticketId: json['ticket_id'] is int
          ? json['ticket_id'] as int
          : int.tryParse('${json['ticket_id'] ?? ''}'),
    );
  }
}
