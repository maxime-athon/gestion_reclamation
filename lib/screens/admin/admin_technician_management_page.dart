import 'package:flutter/material.dart';

// écran de gestion des techniciens pour les administrateurs qui permet d'ajouter, activer/désactiver, et voir les détails de chaque technicien   
import '../../constants/app_colors.dart';
// La page affiche une liste des techniciens avec leur nom, email, rôle, statut de compte, et des actions pour gérer leur statut (actif/inactif) ou accéder à leurs détails 
// Les administrateurs peuvent facilement ajouter de nouveaux techniciens via un bouton dédié, et chaque technicien peut être activé ou désactivé en fonction de leur disponibilité ou de leur statut au sein de l'organisation

class AdminTechnicianManagementPage extends StatelessWidget {
  final List<Map<String, dynamic>> technicians;
  final VoidCallback onAddTechnician;
  final Future<void> Function(Map<String, dynamic> technician) onToggleActive;

  const AdminTechnicianManagementPage({
    super.key,
    required this.technicians,
    required this.onAddTechnician,
    required this.onToggleActive,
  });
  
  static const _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gestion des Utilisateurs', style: TextStyle(color: _primaryColor, fontSize: 22, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Citoyens et Corps Technique', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onAddTechnician,
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Ajouter un Technicien', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
              columns: const [
                DataColumn(label: Text('Nom Complet')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Statut Compte')),
                DataColumn(label: Text('Actions')),
              ],
              rows: technicians.map((tech) {
                final name = '${tech['first_name'] ?? ''} ${tech['last_name'] ?? ''}'.trim();
                final email = tech['email']?.toString() ?? '-';
                final isActive = tech['is_active'] != false;
                return DataRow(cells: [
                  DataCell(Text(name.isEmpty ? 'Technicien' : name, style: const TextStyle(fontWeight: FontWeight.w700))),
                  DataCell(Text(email, style: const TextStyle(color: Color(0xFF6B7280), fontStyle: FontStyle.italic))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(999)),
                    child: const Text('TECHNICIEN', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 10, fontWeight: FontWeight.w900)),
                  )),
                  DataCell(Row(children: [
                    Icon(Icons.circle, size: 10, color: isActive ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF)),
                    const SizedBox(width: 8),
                    Text(
                      isActive ? 'Actif' : 'Desactive',
                      style: TextStyle(
                        color: isActive ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ])),
                  DataCell(
                    IconButton(
                      onPressed: () => onToggleActive(tech),
                      icon: Icon(
                        isActive ? Icons.no_accounts : Icons.person_add_alt_1,
                        color: isActive ? const Color(0xFF9CA3AF) : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
