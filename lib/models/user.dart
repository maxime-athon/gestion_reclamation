import 'dart:convert';
// modèle de données représentant un utilisateur de l'application
// il est utilisé pour stocker les informations de l'utilisateur connecté et les afficher dans la section profil de l'application
// le modèle de données de l'utilisateur contient les informations suivantes :
// - id : l'identifiant unique de l'utilisateur
// - email : l'adresse email de l'utilisateur
// - role : le rôle de l'utilisateur (ex: "ADMIN", "TECHNICIEN", "CITOYEN")
// - username : le nom d'utilisateur de l'utilisateur (ex: "johndoe")
// - firstName : le prénom de l'utilisateur
// - lastName : le nom de famille de l'utilisateur
// - fullName : le nom complet de l'utilisateur (prénom + nom de famille)
// - telephone : le numéro de téléphone de l'utilisateur
// - isActive : un booléen indiquant si le compte de l'utilisateur est actif ou non (ex: true, false)

class AppUser {
  final int id;
  final String email;
  final String role;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String telephone;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.telephone,
    required this.isActive,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final firstName = (json['first_name'] ?? '').toString();
    final lastName = (json['last_name'] ?? '').toString();
    final fullName = (json['full_name'] ?? '').toString().trim();

    return AppUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'CITOYEN').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: firstName,
      lastName: lastName,
      fullName: fullName.isNotEmpty
          ? fullName
          : '$firstName $lastName'.trim(),
      telephone: (json['telephone'] ?? '').toString(),
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'telephone': telephone,
        'is_active': isActive,
      };

  String toStorage() => jsonEncode(toJson());

  factory AppUser.fromStorage(String raw) {
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
