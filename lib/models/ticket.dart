// cet fichier contient le modele de ticket de l'application
// il est utilisé pour stocker les informations des tickets récupérées depuis l'API et les
// afficher dans les différentes sections de l'application (liste des tickets, détail du ticket, etc.)
// le modèle de ticket contient les informations suivantes :
// - id : l'identifiant unique du ticket
// - numeroTicket : le numéro du ticket (ex: TK-1234)
// - titre : le titre du ticket
// - description : la description du problème signalé dans le ticket
// - typeTicket : le type de ticket (ex: "Incident", "Demande",
//   "Problème", etc.)
// - statut : le statut actuel du ticket (ex: "Nouveau", "En cours", "Résolu", etc.)
// - priorite : la priorité du ticket (ex: "Basse", "Moyenne", "Haute")
// - auteurNom : le nom de l'auteur du ticket
// - dateCreation : la date de création du ticket
// - dateResolution : la date de résolution du ticket (si applicable)
// - assigneA : le nom de la personne à qui le ticket est assigné (si applicable)
// - commentairesCount : le nombre de commentaires associés au ticket
// - commentaires : la liste des commentaires associés au ticket (si applicable)  

class TicketComment {
  final int id;
  final int authorId;
  final String authorName;
  final String authorEmail;
  final String authorRole;
  final String content;
  final String createdAt;

  const TicketComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorEmail,
    required this.authorRole,
    required this.content,
    required this.createdAt,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    final author = json['auteur'] as Map<String, dynamic>? ?? const {};
    final fullName = (author['full_name'] ?? '').toString().trim();
    final firstName = (author['first_name'] ?? '').toString();
    final lastName = (author['last_name'] ?? '').toString();

    return TicketComment(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      authorId: author['id'] is int ? author['id'] as int : int.tryParse('${author['id']}') ?? 0,
      authorName: fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim(),
      authorEmail: (author['email'] ?? '').toString(),
      authorRole: (author['role'] ?? '').toString(),
      content: (json['contenu'] ?? '').toString(),
      createdAt: (json['date'] ?? '').toString(),
    );
  }
}

class Ticket {
  final int id;
  final String numeroTicket;
  final String titre;
  final String description;
  final String typeTicket;
  final String statut;
  final String priorite;
  final String auteurNom;
  final String dateCreation;
  final String? dateResolution;
  final String? assigneA;
  final int commentairesCount;
  final List<TicketComment> commentaires;

  Ticket({
    required this.id,
    required this.numeroTicket,
    required this.titre,
    required this.description,
    required this.typeTicket,
    required this.statut,
    required this.priorite,
    required this.auteurNom,
    required this.dateCreation,
    this.dateResolution,
    this.assigneA,
    this.commentairesCount = 0,
    this.commentaires = const [],
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final auteur = json['auteur'] as Map<String, dynamic>?;
    final assigne = json['assigne_a'] as Map<String, dynamic>?;
    final commentairesRaw = json['commentaires'] as List<dynamic>?;

    return Ticket(
      id: json['id'] ?? 0,
      numeroTicket: (json['numero_ticket'] ?? 'TK-${json['id'] ?? 0}').toString(),
      titre: (json['titre'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      typeTicket: (json['type_ticket'] ?? '').toString(),
      statut: (json['statut'] ?? '').toString(),
      priorite: (json['priorite'] ?? '').toString(),
      auteurNom: auteur != null
          ? '${auteur['first_name'] ?? ''} ${auteur['last_name'] ?? ''}'.trim()
          : 'Inconnu',
      dateCreation: (json['date_creation'] ?? '').toString(),
      dateResolution: json['date_resolution']?.toString(),
      assigneA: assigne != null
          ? '${assigne['first_name'] ?? ''} ${assigne['last_name'] ?? ''}'.trim()
          : null,
      commentairesCount: json['commentaires_count'] is int
          ? json['commentaires_count'] as int
          : int.tryParse('${json['commentaires_count'] ?? 0}') ?? 0,
      commentaires: commentairesRaw == null
          ? const []
          : commentairesRaw
              .whereType<Map<String, dynamic>>()
              .map(TicketComment.fromJson)
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'titre': titre,
        'description': description,
        'type_ticket': typeTicket,
        'priorite': priorite,
      };
}
