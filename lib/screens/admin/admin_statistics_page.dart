import 'package:flutter/material.dart';

import '../../models/ticket.dart';
import '../../constants/app_colors.dart';

// écran de statistiques pour les administrateurs qui présente des graphiques et des indicateurs clés basés sur les données des tickets et des interventions en cours
// Les statistiques incluent la répartition des types de tickets, les taux de résolution, les performances des techniciens, et d'autres métriques pertinentes pour le suivi et l'optimisation des processus de gestion des tickets
// Le design de la page de statistiques est pensé pour être clair et visuellement attrayant, avec des graphiques colorés et des indicateurs facilement compréhensibles

class AdminStatisticsPage extends StatelessWidget {
  final List<Ticket> tickets;
  final Map<String, dynamic> stats;

  const AdminStatisticsPage({
    super.key,
    required this.tickets,
    required this.stats,
  });

  static const _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final typeCounts = _countByType(tickets);
    final totalTickets = (stats['total_tickets'] as num?)?.toInt() ?? tickets.length;
    final total = totalTickets == 0 ? 1 : totalTickets;
    final incidentRatio = typeCounts['INCIDENT']! / total;
    final reclamationRatio = typeCounts['RECLAMATION']! / total;
    final demandeRatio = typeCounts['DEMANDE']! / total;
    final resolvedTickets = (stats['resolved_tickets'] as num?)?.toInt() ?? tickets.where((ticket) => ticket.statut == 'RESOLU' || ticket.statut == 'CLOS').length;
    final criticalTickets = (stats['critical_tickets'] as num?)?.toInt() ?? tickets.where((ticket) => ticket.priorite == 'CRITIQUE').length;
    final resolutionRate = totalTickets == 0 ? 0.0 : resolvedTickets / totalTickets;
    final criticalRate = totalTickets == 0 ? 0.0 : criticalTickets / totalTickets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 1100 ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: MediaQuery.of(context).size.width >= 1100 ? 1.5 : 1.1,
          children: [
            _distributionCard(incidentRatio, reclamationRatio, demandeRatio),
            _performanceCard(
              resolvedTickets: resolvedTickets,
              totalTickets: totalTickets,
              resolutionRate: resolutionRate,
              criticalRate: criticalRate,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _priorityCard(context, criticalTickets),
      ],
    );
  }

  Widget _distributionCard(double incidentRatio, double reclamationRatio, double demandeRatio) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.pie_chart, color: _primaryColor),
          SizedBox(width: 8),
          Text('REPARTITION PAR TYPE', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar('Incidents', const Color(0xFFF97316), incidentRatio),
              _bar('Reclams.', const Color(0xFFA855F7), reclamationRatio),
              _bar('Demandes', const Color(0xFF3B82F6), demandeRatio),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _performanceCard({
    required int resolvedTickets,
    required int totalTickets,
    required double resolutionRate,
    required double criticalRate,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x22006743), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.speed, color: Colors.white70),
          SizedBox(width: 8),
          Text('PERFORMANCE EQUIPE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 28),
        const Text('Taux de resolution', style: TextStyle(color: Colors.white, fontSize: 13)),
        const SizedBox(height: 8),
        Text('$resolvedTickets / $totalTickets tickets traites', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: resolutionRate.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: const Color(0x22FFFFFF),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x22FFFFFF))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PART DES TICKETS CRITIQUES', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('${(criticalRate * 100).toStringAsFixed(1)} %', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
          ]),
        ),
      ]),
    );
  }

  Widget _priorityCard(BuildContext context, int criticalTickets) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Configuration des Priorites', style: TextStyle(color: _primaryColor, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 950 ? 2 : 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.7,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(999)),
                    child: const Text('CRITIQUE', style: TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                  const Spacer(),
                  Text('$criticalTickets ticket(s)', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 16),
                const Text('Les tickets critiques exigent une prise en charge immediate et une surveillance prioritaire.', style: TextStyle(color: Color(0xFF4B5563), fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Text('Priorite monitorée dynamiquement', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w700)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, color: Color(0xFF9CA3AF), size: 34),
                  SizedBox(height: 10),
                  Text('Les regles metier pourront evoluer ensuite sans changer le design.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w700, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _bar(String label, Color color, double ratio) {
    final safeRatio = ratio.clamp(0.08, 1.0);
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Container(width: 42, height: 140 * safeRatio, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))),
      const SizedBox(height: 10),
      Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w700)),
    ]);
  }

  Map<String, int> _countByType(List<Ticket> tickets) {
    final counts = {'INCIDENT': 0, 'RECLAMATION': 0, 'DEMANDE': 0};
    for (final ticket in tickets) {
      counts[ticket.typeTicket] = (counts[ticket.typeTicket] ?? 0) + 1;
    }
    return counts;
  }
}
