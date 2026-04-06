import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/ticket.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/feedback_banner.dart';
import '../profile_screen.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

// écran de liste des tickets qui affiche les tickets de l'utilisateur avec des options de filtrage par statut et par type, et un bouton pour créer un nouveau ticket
//il affiche les tickets sous forme de cartes avec des informations clés (titre, numéro, date, statut, priorité, nombre de commentaires) et une couleur de bordure indiquant le type de ticket (incident, reclamation, demande)
//il gère également les états de chargement, d'erreur et de liste vide avec des composants visuels adaptés (indicateur de chargement, bannière d'erreur, message d'état vide)
//il utilise un IndexedStack pour permettre une navigation fluide entre les différentes sections de l'application (tickets, profil, admin/technicien) tout en conservant l'état de chaque section
//il utilise des méthodes privées pour construire les différentes parties de l'interface (barre supérieure, filtres, sections de tickets, cartes de tickets) et pour appliquer les filtres aux tickets affichés
//il utilise des styles cohérents pour les éléments de l'interface (couleurs, typographie, espacements) pour assurer une expérience utilisateur agréable et intuitive

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  String? _statusFilter;
  String? _typeFilter;

  Future<void> _loadTickets() async {
    await context.read<TicketProvider>().fetchTickets(statut: _statusFilter);
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final allTickets = ticketProvider.tickets;
    final visibleTickets = _applyTypeFilter(allTickets);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton( 
        backgroundColor: AppColors.primary,
        elevation: 14,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
        ).then((_) => _loadTickets()),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            _buildStatusFilters(),
            _buildTypeFilters(),
            Expanded(
              child: ticketProvider.loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator( 
                      color: AppColors.primary,
                      onRefresh: _loadTickets,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: [
                          if (ticketProvider.error != null) ...[
                            FeedbackBanner(message: ticketProvider.error!),
                            const SizedBox(height: 16),
                          ],
                          if (visibleTickets.isEmpty)
                            _buildEmptyState()
                          else
                            ..._buildSections(visibleTickets),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number, color: Colors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Mes Tickets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.account_circle, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip('Tous', null),
            _buildStatusChip('En cours', 'EN_COURS'),
            _buildStatusChip('Resolus', 'RESOLU'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String? value) {
    final isSelected = _statusFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _statusFilter = value;
          });
          _loadTickets();
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration( 
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x22006743),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF4B5563), 
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildTypeButton(
              label: 'Tous',
              icon: Icons.all_inclusive,
              color: Colors.grey,
              value: null,
            ),
            _buildTypeButton(
              label: 'Incidents',
              icon: Icons.warning,
              color: Colors.orange,
              value: 'INCIDENT',
            ),
            _buildTypeButton(
              label: 'Reclams.',
              icon: Icons.campaign,
              color: Colors.purple,
              value: 'RECLAMATION',
            ),
            _buildTypeButton(
              label: 'Demandes',
              icon: Icons.help_center,
              color: Colors.blue,
              value: 'DEMANDE',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required Color color,
    required String? value,
  }) {
    final isSelected = _typeFilter == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _typeFilter = value;
          });
          context.read<TicketProvider>().clearError();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? AppColors.primary : color,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : const Color(0xFF6B7280),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Ticket> _applyTypeFilter(List<Ticket> tickets) {
    if (_typeFilter == null) {
      return tickets;
    }
    return tickets.where((ticket) => ticket.typeTicket == _typeFilter).toList();
  }

  List<Widget> _buildSections(List<Ticket> tickets) {
    if (_typeFilter != null) {
      return [
        _buildSection(
          title: _sectionTitleForType(_typeFilter!),
          tickets: tickets,
        ),
      ];
    }

    final incidents = tickets.where((ticket) => ticket.typeTicket == 'INCIDENT').toList();
    final reclamations = tickets.where((ticket) => ticket.typeTicket == 'RECLAMATION').toList();
    final demandes = tickets.where((ticket) => ticket.typeTicket == 'DEMANDE').toList();
    final otherTickets = tickets
        .where(
          (ticket) =>
              ticket.typeTicket != 'INCIDENT' &&
              ticket.typeTicket != 'RECLAMATION' &&
              ticket.typeTicket != 'DEMANDE',
        )
        .toList();

    final sections = <Widget>[];

    if (incidents.isNotEmpty) {
      sections.add(_buildSection(title: 'Incidents Recents', tickets: incidents));
    }
    if (reclamations.isNotEmpty) {
      sections.add(_buildSection(title: 'Vos Reclamations', tickets: reclamations));
    }
    if (demandes.isNotEmpty) {
      sections.add(_buildSection(title: 'Vos Demandes', tickets: demandes));
    }
    if (otherTickets.isNotEmpty) {
      sections.add(_buildSection(title: 'Autres Tickets', tickets: otherTickets));
    }

    return sections;
  }

  Widget _buildSection({
    required String title,
    required List<Ticket> tickets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 1,
                color: const Color(0xFFE5E7EB),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tickets.map(_buildTicketCard),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final typeStyle = _typeStyle(ticket.typeTicket);
    final statusStyle = _statusStyle(ticket.statut);
    final isResolved = ticket.statut == 'RESOLU' || ticket.statut == 'CLOS';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticketId: ticket.id),
            ),
          ).then((_) => _loadTickets()),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isResolved ? 0.82 : 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border(
                  left: BorderSide(color: typeStyle.borderColor, width: 6),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.titre,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isResolved
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF1F2937),
                                decoration:
                                    isResolved ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _metaLine(ticket, isResolved),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusStyle.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusStyle.label.toUpperCase(),
                          style: TextStyle(
                            color: statusStyle.foreground,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.priority_high,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Priorite : ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      Text(
                        _priorityLabel(ticket.priorite),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _priorityColor(ticket.priorite),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ticket.commentairesCount == 1
                            ? '1 commentaire'
                            : '${ticket.commentairesCount} commentaires',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                  if (_typeFilter == null) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeStyle.background,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          typeStyle.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            letterSpacing: .5,
                            color: typeStyle.foreground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 44,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucun ticket pour ce filtre',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Essayez un autre statut, changez de categorie ou creez un nouveau ticket.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _statusFilter = null;
                _typeFilter = null;
              });
              _loadTickets();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reinitialiser les filtres'),
          ),
        ],
      ),
    );
  }

  String _metaLine(Ticket ticket, bool isResolved) {
    final dateLabel = isResolved ? 'Résolu le' : 'Créé le';
    final rawDate =
        isResolved && (ticket.dateResolution?.isNotEmpty ?? false)
            ? ticket.dateResolution!
            : ticket.dateCreation;
    return 'Ticket #${ticket.numeroTicket} • $dateLabel ${_formatDate(rawDate)}';
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return raw;
    }
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year}';
  }

  String _sectionTitleForType(String type) {
    switch (type) {
      case 'INCIDENT':
        return 'Incidents Recents';
      case 'RECLAMATION':
        return 'Vos Reclamations';
      case 'DEMANDE':
        return 'Vos Demandes';
      default:
        return 'Tickets';
    }
  }

  _ChipStyle _typeStyle(String type) {
    switch (type) {
      case 'INCIDENT':
        return const _ChipStyle(
          label: 'Incident',
          borderColor: Color(0xFFF97316),
          background: Color(0xFFFFEDD5),
          foreground: Color(0xFFEA580C),
        );
      case 'RECLAMATION':
        return const _ChipStyle(
          label: 'Reclamation',
          borderColor: Color(0xFFA855F7),
          background: Color(0xFFF3E8FF),
          foreground: Color(0xFF9333EA),
        );
      case 'DEMANDE':
        return const _ChipStyle(
          label: 'Demande',
          borderColor: Color(0xFF3B82F6),
          background: Color(0xFFDBEAFE),
          foreground: Color(0xFF2563EB),
        );
      default:
        return const _ChipStyle(
          label: 'Ticket',
          borderColor: Color(0xFF9CA3AF),
          background: Color(0xFFF3F4F6),
          foreground: Color(0xFF4B5563),
        );
    }
  }

  _ChipStyle _statusStyle(String status) {
    switch (status) {
      case 'EN_COURS':
        return const _ChipStyle(
          label: 'En cours',
          borderColor: Color(0xFFF97316),
          background: Color(0xFFFFEDD5),
          foreground: Color(0xFFEA580C),
        );
      case 'RESOLU':
        return const _ChipStyle(
          label: 'Resolu',
          borderColor: Color(0xFF22C55E),
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF16A34A),
        );
      case 'CLOS':
        return const _ChipStyle(
          label: 'Clos',
          borderColor: Color(0xFF22C55E),
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF16A34A),
        );
      default:
        return const _ChipStyle(
          label: 'Ouvert',
          borderColor: Color(0xFF3B82F6),
          background: Color(0xFFDBEAFE),
          foreground: Color(0xFF2563EB),
        );
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'CRITIQUE':
        return 'Critique';
      case 'HAUTE':
        return 'Haute';
      case 'NORMALE':
        return 'Normale';
      case 'BASSE':
        return 'Basse';
      default:
        return priority;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'CRITIQUE':
        return const Color(0xFFB91C1C);
      case 'HAUTE':
        return const Color(0xFFEF4444);
      case 'NORMALE':
        return const Color(0xFFF59E0B);
      case 'BASSE':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _ChipStyle {
  final String label;
  final Color borderColor;
  final Color background;
  final Color foreground;

  const _ChipStyle({
    required this.label,
    required this.borderColor,
    required this.background,
    required this.foreground,
  });
}
