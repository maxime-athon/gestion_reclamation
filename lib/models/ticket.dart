// cet fichier contient le modele de ticket de l'application
// il est utilisé pour stocker les informations des tickets récupérées depuis l'API et les
// afficher dans les différentes sections de l'application (liste des tickets, détail du ticket, etc.)

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
    
    // Récupération sécurisée des IDs
    final rawId = json['id'];
    final parsedId = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
    
    final rawAuthId = author['id'];
    final parsedAuthId = rawAuthId is int ? rawAuthId : int.tryParse('$rawAuthId') ?? 0;

    // Gestion du nom complet (priorité au full_name du backend)
    final fullName = (author['full_name'] ?? '').toString().trim();
    final firstName = (author['first_name'] ?? '').toString();
    final lastName = (author['last_name'] ?? '').toString();
    final finalName = fullName.isNotEmpty ? fullName : '$firstName $lastName'.trim();

    return TicketComment(
      id: parsedId,
      authorId: parsedAuthId,
      authorName: finalName.isEmpty ? 'Utilisateur' : finalName,
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

    // Sécurisation de l'ID du ticket
    final rawId = json['id'];
    final parsedId = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;

    // Extraction du nom de l'auteur
    String authorFinalName = 'Inconnu';
    if (auteur != null) {
      final fn = (auteur['full_name'] ?? '').toString().trim();
      authorFinalName = fn.isNotEmpty 
          ? fn 
          : '${auteur['first_name'] ?? ''} ${auteur['last_name'] ?? ''}'.trim();
    }

    // Extraction du nom de l'assigné
    String? assignedFinalName;
    if (assigne != null) {
      final afn = (assigne['full_name'] ?? '').toString().trim();
      assignedFinalName = afn.isNotEmpty 
          ? afn 
          : '${assigne['first_name'] ?? ''} ${assigne['last_name'] ?? ''}'.trim();
    }

    return Ticket(
      id: parsedId,
      numeroTicket: (json['numero_ticket'] ?? 'TK-$parsedId').toString(),
      titre: (json['titre'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      typeTicket: (json['type_ticket'] ?? '').toString(),
      statut: (json['statut'] ?? '').toString(),
      priorite: (json['priorite'] ?? '').toString(),
      auteurNom: authorFinalName.isEmpty ? 'Inconnu' : authorFinalName,
      dateCreation: (json['date_creation'] ?? '').toString(),
      dateResolution: json['date_resolution']?.toString(),
      assigneA: (assignedFinalName != null && assignedFinalName.isNotEmpty) ? assignedFinalName : null,
      commentairesCount: json['commentaires_count'] is int
          ? json['commentaires_count'] as int
          : int.tryParse('${json['commentaires_count'] ?? 0}') ?? 0,
      commentaires: commentairesRaw == null
          ? const []
          : commentairesRaw
              .whereType<Map<String, dynamic>>()
              .map((c) => TicketComment.fromJson(c))
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
