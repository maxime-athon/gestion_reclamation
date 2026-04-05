import 'package:flutter/material.dart';

import '../../models/ticket.dart';
import '../../constants/app_colors.dart';

// écran d'accueil de l'administrateur
// Le dashboard offre une vue d'ensemble des tickets, la gestion des techniciens, et l'accès à des statistiques détaillées sur les interventions en cours et passées
// Le dashboard est divisé en plusieurs sections accessibles via une barre latérale, permettant à l'administrateur de naviguer facilement entre les différentes fonctionnalités de gestion et de pilotage des tickets et des techniciens
// Les fonctionnalités clés incluent :
// - Vue d'ensemble avec des statistiques clés et des raccourcis vers les sections de gestion
// - Gestion des tickets avec options de recherche, filtrage, assignation, et actions rapides
// - Gestion des techniciens avec possibilité d'ajouter, activer/désactiver, et voir les détails de chaque technicien
// - Statistiques détaillées avec des graphiques et des rapports basés sur les données des tickets et des interventions en cours
// Le design du dashboard est pensé pour être clair, intuitif, et responsive, offrant une expérience utilisateur optimale sur desktop et tablette, avec une navigation adaptée sur mobile
class AdminOverviewPage extends StatelessWidget {
  final List<Ticket> tickets;
  final VoidCallback onOpenTickets;
  final VoidCallback onOpenTechnicians;
  final VoidCallback onOpenStatistics;
  final VoidCallback onExportPdf;

  const AdminOverviewPage({
    super.key,
    required this.tickets,
    required this.onOpenTickets,
    required this.onOpenTechnicians,
    required this.onOpenStatistics,
    required this.onExportPdf,
  });

  static const _primaryColor = AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final waiting = tickets.where((t) => (t.assigneA == null || t.assigneA!.isEmpty) && t.statut == 'OUVERT').length;
    final inProgress = tickets.where((t) => t.statut == 'EN_COURS').length;
    final resolved = tickets.where((t) => t.statut == 'RESOLU' || t.statut == 'CLOS').length;
    final critical = tickets.where((t) => t.priorite == 'CRITIQUE').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tableau de Bord', style: TextStyle(color: _primaryColor, fontSize: 30, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Bienvenue sur la tour de controle de l\'Univ Kara.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onExportPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0x22006743),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Rapport PDF', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 1200 ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: MediaQuery.of(context).size.width >= 600 ? 1.6 : 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _kpiCard('En attente d\'assignation', waiting, const Color(0xFFF97316)),
            _kpiCard('En cours de traitement', inProgress, _primaryColor),
            _kpiCard('Resolus (Ce mois)', resolved, const Color(0xFF22C55E)),
            _kpiCard('Tickets Critiques', critical, const Color(0xFFEF4444)),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width >= 1000 ? 3 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _quickCard(title: 'Gestion Tickets', subtitle: 'Assigner, suivre, modifier et controler les reclamations.', icon: Icons.confirmation_number, onTap: onOpenTickets),
            _quickCard(title: 'Gestion Techniciens', subtitle: 'Ajouter des techniciens et superviser les comptes actifs.', icon: Icons.group, onTap: onOpenTechnicians),
            _quickCard(title: 'Statistiques', subtitle: 'Suivre la performance, la repartition et les priorites.', icon: Icons.pie_chart, onTap: onOpenStatistics),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border(bottom: BorderSide(color: color, width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value.toString().padLeft(2, '0'),
              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 42, fontWeight: FontWeight.w900, height: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _primaryColor, size: 28),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: _primaryColor, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.45)),
            ],
          ),
        ),
      ),
    );
  }
}
