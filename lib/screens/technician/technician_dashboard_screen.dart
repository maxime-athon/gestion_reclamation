import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/feedback_banner.dart';
import '../notifications/notifications_screen.dart';
import 'technician_ticket_detail_screen.dart';

// écran de tableau de bord pour les techniciens qui affiche les interventions qui leur sont assignées, avec des statistiques sur les tickets urgents, en cours et terminés aujourd'hui, et un accès rapide aux notifications et au détail de chaque ticket
class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  State<TechnicianDashboardScreen> createState() => _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  bool _sortByUrgency = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTickets();
      if (mounted) {
        await context.read<TicketProvider>().fetchNotifications();
      }
    });
  }

  Future<void> _loadTickets() async {
    await context.read<TicketProvider>().fetchTickets(assignedToMe: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final tickets = List<Ticket>.from(provider.tickets);

    tickets.sort((a, b) {
      if (_sortByUrgency) {
        return _priorityRank(b.priorite).compareTo(_priorityRank(a.priorite));
      }
      final dateA = DateTime.tryParse(a.dateCreation) ?? DateTime(2000);
      final dateB = DateTime.tryParse(b.dateCreation) ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    final urgentCount = tickets.where((ticket) => _priorityRank(ticket.priorite) >= 3).length;
    final inProgressCount = tickets.where((ticket) => ticket.statut == 'EN_COURS').length;
    final completedToday = tickets.where((ticket) {
      if (ticket.statut != 'RESOLU' && ticket.statut != 'CLOS') {
        return false;
      }
      final rawDate = ticket.dateResolution ?? ticket.dateCreation;
      final date = DateTime.tryParse(rawDate)?.toLocal();
      final now = DateTime.now();
      return date != null && date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadTickets,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    if (provider.error != null) ...[
                      FeedbackBanner(message: provider.error!),
                      const SizedBox(height: 16),
                    ],
                    _buildStats(urgentCount, inProgressCount, completedToday),
                    const SizedBox(height: 20),
                    _buildInterventionsCard(provider, tickets),
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
    final unreadCount = context.watch<TicketProvider>().unreadNotificationsCount;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final displayName = user?.fullName.isNotEmpty == true ? user!.fullName : (user?.email ?? 'Technicien');

    return Container(
      color: AppColors.primaryDark, // Utilisation de AppColors.primaryDark
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.engineering, color: Colors.white),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Espace Technique',
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              displayName,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ).then((_) => context.read<TicketProvider>().fetchNotifications()),
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications, color: Colors.white),
                  if (unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int urgentCount, int inProgressCount, int completedToday) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width >= 700 ? 3 : 1,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: [ // Utilisation de AppColors.primary pour "En cours"
        _buildStatCard(label: 'A traiter d urgence', value: urgentCount, color: const Color(0xFFEF4444), icon: Icons.priority_high), 
        _buildStatCard(label: 'En cours', value: inProgressCount, color: const Color(0xFF006743), icon: Icons.pending_actions),
        _buildStatCard(label: 'Termines aujourd hui', value: completedToday, color: const Color(0xFF22C55E), icon: Icons.task_alt),
      ],
    );
  }

  Widget _buildStatCard({required String label, required int value, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border(left: BorderSide(color: color, width: 8)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value.toString().padLeft(2, '0'), style: const TextStyle(color: Color(0xFF1F2937), fontSize: 40, fontWeight: FontWeight.w900, height: 1)),
              const Spacer(),
              Icon(icon, color: color, size: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionsCard(TicketProvider provider, List<Ticket> tickets) {
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
                  child: Text(
                    'Mes Interventions',
                    style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w900),
              ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSortButton(label: 'Plus recents', selected: !_sortByUrgency, danger: false, onTap: () => setState(() => _sortByUrgency = false)),
                    _buildSortButton(label: 'Plus urgents', selected: _sortByUrgency, danger: true, onTap: () => setState(() => _sortByUrgency = true)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          if (provider.loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (tickets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aucune intervention assignee pour le moment.',
                style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                columns: const [
                  DataColumn(label: Text('Ticket & Type')),
                  DataColumn(label: Text('Urgence')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Action')),
                ],
                rows: tickets.map((ticket) {
                  return DataRow(cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '#${ticket.numeroTicket} • ${ticket.titre}',
                            style: const TextStyle(color: Color(0xFF1F2937), fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.category, size: 13, color: Color(0xFF6B7280)),
                              const SizedBox(width: 4),
                              Text(
                                ticket.typeTicket,
                                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(_buildUrgencyPill(ticket.priorite)),
                    DataCell(_buildStatusCell(ticket.statut)),
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TechnicianTicketDetailScreen(ticketId: ticket.id)),
                          ).then((_) => _loadTickets()),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [BoxShadow(color: Color(0x22006743), blurRadius: 10, offset: Offset(0, 4))],
                            ),
                            child: const Icon(Icons.chat, color: Colors.white, size: 20),
                          ),
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

  Widget _buildSortButton({required String label, required bool selected, required bool danger, required VoidCallback onTap}) {
    final bg = selected ? (danger ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6)) : const Color(0xFFF9FAFB);
    final fg = danger ? const Color(0xFFDC2626) : const Color(0xFF4B5563);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildUrgencyPill(String priority) {
    final style = switch (priority) {
      'CRITIQUE' => _PillStyle(bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C), label: 'CRITIQUE'),
      'HAUTE' => _PillStyle(bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C), label: 'HAUTE'),
      'NORMALE' => _PillStyle(bg: const Color(0xFFDBEAFE), fg: const Color(0xFF1D4ED8), label: 'NORMALE'),
      _ => _PillStyle(bg: const Color(0xFFECFDF5), fg: const Color(0xFF047857), label: 'BASSE'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: style.fg.withOpacity(.18))),
      child: Text(style.label, style: TextStyle(color: style.fg, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .4)),
    );
  }

  Widget _buildStatusCell(String status) {
    final style = switch (status) {
      'EN_COURS' => _StatusStyle(dotColor: const Color(0xFFF97316), textColor: const Color(0xFFEA580C), label: 'En cours', pulse: true),
      'OUVERT' => _StatusStyle(dotColor: const Color(0xFF9CA3AF), textColor: const Color(0xFF6B7280), label: 'Assigne', pulse: false),
      _ => _StatusStyle(dotColor: const Color(0xFF22C55E), textColor: const Color(0xFF16A34A), label: 'Resolu', pulse: false),
    };

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: style.dotColor,
            shape: BoxShape.circle,
            boxShadow: style.pulse ? [BoxShadow(color: style.dotColor.withOpacity(.4), blurRadius: 8, spreadRadius: 1)] : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(style.label.toUpperCase(), style: TextStyle(color: style.textColor, fontSize: 11, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
      ],
    );
  }

  int _priorityRank(String priority) {
    switch (priority) {
      case 'CRITIQUE':
        return 4;
      case 'HAUTE':
        return 3;
      case 'NORMALE':
        return 2;
      case 'BASSE':
        return 1;
      default:
        return 0;
    }
  }
}

class _PillStyle {
  final Color bg;
  final Color fg;
  final String label;

  _PillStyle({required this.bg, required this.fg, required this.label});
}

class _StatusStyle {
  final Color dotColor;
  final Color textColor;
  final String label;
  final bool pulse;

  _StatusStyle({required this.dotColor, required this.textColor, required this.label, required this.pulse});
}
