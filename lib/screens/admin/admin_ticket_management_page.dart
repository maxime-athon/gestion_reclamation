import 'package:flutter/material.dart';

import '../../models/ticket.dart';
import '../../constants/app_colors.dart';

// écran de gestion des tickets pour les administrateurs qui offre des fonctionnalités avancées de recherche, filtrage, assignation, et actions rapides sur les tickets
// La page affiche une liste des tickets avec des informations clés (ID, sujet, priorité,
// technicien assigné) et des actions pour consulter le détail, modifier le statut, assigner à un technicien, supprimer, ou archiver les tickets
// Les administrateurs peuvent facilement rechercher des tickets spécifiques via une barre de recherche, et chaque ticket peut être rapidement assigné à un technicien ou mis à jour en fonction de l'évolution de sa situation
// Les tickets clos sont affichés avec un statut d'archive, et peuvent être archivés définitivement pour garder la liste des tickets active claire et pertinente    
class AdminTicketManagementPage extends StatelessWidget {
  final TextEditingController searchController;
  final List<Ticket> tickets;
  final List<Map<String, dynamic>> technicians;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Ticket> onViewTicket;
  final Future<void> Function(Ticket ticket, int technicianId) onAssign;
  final Future<void> Function(Ticket ticket) onUpdateStatus;
  final Future<void> Function(Ticket ticket) onDelete;
  final Future<void> Function(Ticket ticket) onArchive;

  const AdminTicketManagementPage({
    super.key,
    required this.searchController,
    required this.tickets,
    required this.technicians,
    required this.onSearchChanged,
    required this.onViewTicket,
    required this.onAssign,
    required this.onUpdateStatus,
    required this.onDelete,
    required this.onArchive,
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
                const Expanded(child: Text('Gestion des Tickets', style: TextStyle(color: _primaryColor, fontSize: 22, fontWeight: FontWeight.w900))),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Chercher un ticket...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                  ),
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
                DataColumn(label: Text('ID / Sujet')),
                DataColumn(label: Text('Priorite')),
                DataColumn(label: Text('Technicien Assigne')),
                DataColumn(label: Text('Actions de Controle')),
              ],
              rows: tickets.take(12).map((ticket) {
                final assignedTech = _selectedTechnicianId(ticket, technicians);
                return DataRow(cells: [
                  DataCell(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#TK-${ticket.id} ${ticket.titre}',
                        style: TextStyle(
                          color: ticket.statut == 'CLOS' ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                          fontWeight: FontWeight.w700,
                          decoration: ticket.statut == 'CLOS' ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Poste par: ${ticket.auteurNom} • ${_relativeTime(ticket.dateCreation)}', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic)),
                    ],
                  )),
                  DataCell(_priorityPill(ticket.priorite)),
                  DataCell(ticket.statut == 'CLOS'
                      ? const Text('Archive', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontStyle: FontStyle.italic))
                      : SizedBox(
                          width: 170,
                          child: DropdownButtonFormField<int?>(
                            value: assignedTech,
                            isDense: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Non assigne')),
                              ...technicians.map((tech) => DropdownMenuItem<int?>(value: tech['id'] as int?, child: Text('${tech['first_name']} ${tech['last_name']}', overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (value) {
                              if (value != null) onAssign(ticket, value);
                            },
                          ),
                        )),
                  DataCell(ticket.statut == 'CLOS'
                      ? Align(alignment: Alignment.centerRight, child: IconButton(onPressed: () => onArchive(ticket), icon: const Icon(Icons.inventory_2, color: Color(0xFF111827))))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(onPressed: () => onViewTicket(ticket), icon: const Icon(Icons.visibility, color: Color(0xFF9CA3AF))),
                          IconButton(onPressed: () => onUpdateStatus(ticket), icon: const Icon(Icons.edit, color: Color(0xFFF97316))),
                          IconButton(onPressed: () => onDelete(ticket), icon: const Icon(Icons.delete, color: Color(0xFFEF4444))),
                        ])),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityPill(String priority) {
    final color = switch (priority) {
      'CRITIQUE' => const Color(0xFFDC2626),
      'HAUTE' => const Color(0xFFEF4444),
      'NORMALE' => const Color(0xFFF59E0B),
      'BASSE' => const Color(0xFF10B981),
      _ => const Color(0xFF6B7280),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(.12))),
      child: Text(priority, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .6)),
    );
  }

  int? _selectedTechnicianId(Ticket ticket, List<Map<String, dynamic>> technicians) {
    final assignedName = ticket.assigneA?.trim();
    if (assignedName == null || assignedName.isEmpty) return null;
    for (final tech in technicians) {
      final fullName = '${tech['first_name'] ?? ''} ${tech['last_name'] ?? ''}'.trim();
      if (fullName == assignedName) return tech['id'] as int?;
    }
    return null;
  }

  String _relativeTime(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return 'Date inconnue';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours}h';
    return 'Il y a ${difference.inDays}j';
  }
}
