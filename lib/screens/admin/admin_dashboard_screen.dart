import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/feedback_banner.dart';
import '../auth/login_screen.dart';
import '../tickets/ticket_detail_screen.dart';
import 'admin_overview_page.dart';
import 'admin_statistics_page.dart';
import 'admin_technician_management_page.dart';
import 'admin_ticket_management_page.dart';

// écran de tableau de bord pour les administrateurs qui offre une vue d'ensemble des tickets, la gestion des techniciens, et l'accès à des statistiques détaillées sur les interventions en cours et passées
// Le dashboard est divisé en plusieurs sections accessibles via une barre latérale, permettant à l'administrateur de naviguer facilement entre les différentes fonctionnalités de gestion et de pilotage des tickets et des techniciens
// Les fonctionnalités clés incluent :
// - Vue d'ensemble avec des statistiques clés et des raccourcis vers les sections de gestion
// - Gestion des tickets avec options de recherche, filtrage, assignation, et actions rapides
// - Gestion des techniciens avec possibilité d'ajouter, activer/désactiver, et voir les détails de chaque technicien
// - Statistiques détaillées avec des graphiques et des rapports basés sur les données des tickets et des interventions en cours
// Le design du dashboard est pensé pour être clair, intuitif, et responsive, offrant une expérience utilisateur optimale sur desktop et tablette, avec une navigation adaptée sur mobile via un drawer


enum _AdminSection { overview, tickets, technicians, stats }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchCtrl = TextEditingController();
  final _techFullNameCtrl = TextEditingController();
  final _techEmailCtrl = TextEditingController();
  final _techPhoneCtrl = TextEditingController();
  final _techPasswordCtrl = TextEditingController();
  bool _isTechPasswordVisible = false;
  static const _primaryColor = AppColors.primary;
  _AdminSection _section = _AdminSection.overview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _techFullNameCtrl.dispose();
    _techEmailCtrl.dispose();
    _techPhoneCtrl.dispose();
    _techPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final provider = context.read<TicketProvider>();
    await Future.wait([
      provider.fetchStats(),
      provider.fetchTickets(),
      provider.fetchTechnicians(),
    ]);
  }

  Future<void> _createTechnician() async {
    final fullName = _techFullNameCtrl.text.trim();
    final email = _techEmailCtrl.text.trim();
    final phone = _techPhoneCtrl.text.trim();
    final password = _techPasswordCtrl.text;

    if (fullName.isEmpty || email.isEmpty) {
      AppSnackbar.show(context, message: 'Le nom complet et l\'email sont obligatoires.');
      return;
    }

    // Extraction du prénom et nom pour compatibilité backend
    final nameParts = fullName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final firstName = nameParts.isEmpty ? '' : nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final Map<String, dynamic> userData = {
      'username': email, // Email utilisé comme identifiant unique
      'full_name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'is_active': true,
      'role': 'TECHNICIEN',
    };

    if (phone.isNotEmpty) userData['telephone'] = phone;
    if (password.isNotEmpty) userData['password'] = password;

    final authProvider = context.read<AuthProvider>();
    await authProvider.adminCreateUser(userData);

    if (!mounted) return;
    if (authProvider.error == null) {
      _techFullNameCtrl.clear();
      _techEmailCtrl.clear();
      _techPhoneCtrl.clear();
      _techPasswordCtrl.clear();
      Navigator.of(context).pop();
      AppSnackbar.show(context, message: 'Technicien ajouté. Ses identifiants ont été envoyés par email.', isError: false);
      await context.read<TicketProvider>().fetchTechnicians();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final visibleTickets = provider.tickets.where((ticket) {
      final query = _searchCtrl.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return ticket.titre.toLowerCase().contains(query) || ticket.id.toString().contains(query) || ticket.auteurNom.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: MediaQuery.of(context).size.width >= 900 
          ? null 
          : AppBar(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      drawer: MediaQuery.of(context).size.width >= 900 
          ? null 
          : Drawer(child: _buildSidebar(isDrawer: true)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (isDesktop) 
                SizedBox(width: 264, child: _buildSidebar()),
              Expanded(child: SafeArea(child: _buildBody(provider, visibleTickets))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isDrawer) const SizedBox(height: 32),
        Row(children: [
          const Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ADMIN PANEL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 28),
        _sidebarItem(Icons.dashboard, 'Vue d\'ensemble', _AdminSection.overview),
        const SizedBox(height: 10),
        _sidebarItem(Icons.confirmation_number, 'Gestion Tickets', _AdminSection.tickets),
        const SizedBox(height: 10),
        _sidebarItem(Icons.group, 'Gestion Techniciens', _AdminSection.technicians),
        const SizedBox(height: 10),
        _sidebarItem(Icons.pie_chart, 'Statistiques', _AdminSection.stats),
        if (!isDrawer) const Spacer() else const SizedBox(height: 40),
        const Divider(color: Color(0x22FFFFFF), height: 1),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: () async {
            await context.read<AuthProvider>().logout();
            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
          icon: const Icon(Icons.logout, color: Color(0xFFFECACA)),
          label: const Text('Deconnexion', style: TextStyle(color: Color(0xFFFECACA), fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _sidebarItem(IconData icon, String label, _AdminSection section) {
    final selected = _section == section;
    return InkWell(
      onTap: () {
        setState(() => _section = section);
        if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1AFFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: selected ? const Border(left: BorderSide(color: Colors.white, width: 4)) : null,
        ),
        child: Row(children: [
          Icon(icon, color: selected ? Colors.white : Colors.white70),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildBody(TicketProvider provider, List<Ticket> visibleTickets) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (provider.error != null) ...[FeedbackBanner(message: provider.error!), const SizedBox(height: 20)],
        _buildSectionView(provider, visibleTickets),
      ]),
    );
  }

  Widget _buildSectionView(TicketProvider provider, List<Ticket> visibleTickets) {
    switch (_section) {
      case _AdminSection.overview:
        return AdminOverviewPage(
          tickets: provider.tickets,
          onOpenTickets: () => setState(() => _section = _AdminSection.tickets),
          onOpenTechnicians: () => setState(() => _section = _AdminSection.technicians),
          onOpenStatistics: () => setState(() => _section = _AdminSection.stats),
          onExportPdf: () => _showReportPreview(provider),
        );
      case _AdminSection.tickets:
        return AdminTicketManagementPage(
          searchController: _searchCtrl,
          tickets: visibleTickets,
          technicians: provider.technicians,
          onSearchChanged: (_) => setState(() {}),
          onViewTicket: (ticket) => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: ticket.id))),
          onAssign: (ticket, technicianId) async {
            await provider.assignTicket(ticket.id, technicianId);
            if (!mounted) return;
            if (provider.error == null) {
              AppSnackbar.show(context, message: 'Technicien assigne avec succes.', isError: false);
              await provider.fetchTickets();
            }
          },
          onArchive: (ticket) async {
            await provider.archiveTicket(ticket.id);
            if (!mounted) return;
            if (provider.error == null) {
              AppSnackbar.show(context, message: 'Ticket archive.', isError: false);
              await provider.fetchTickets();
            }
          },
          onDelete: (ticket) async {
            await provider.deleteTicket(ticket.id);
            if (!mounted) return;
            if (provider.error == null) {
              AppSnackbar.show(context, message: 'Ticket supprime.', isError: false);
              await provider.fetchTickets();
            }
          },
          onUpdateStatus: (ticket) async {
            final nextStatus = ticket.statut == 'OUVERT' ? 'EN_COURS' : 'RESOLU';
            await provider.updateStatut(ticket.id, nextStatus);
            if (!mounted) return;
            if (provider.error == null) {
              AppSnackbar.show(context, message: 'Statut mis a jour.', isError: false);
              await provider.fetchTickets();
            }
          },
        );
      case _AdminSection.technicians:
        return AdminTechnicianManagementPage(
          technicians: provider.technicians,
          onAddTechnician: _showTechnicianModal,
          onToggleActive: (technician) async {
            final isActive = technician['is_active'] != false;
            await provider.updateTechnicianStatus(
              technician['id'] as int,
              !isActive,
            );
            if (!mounted) return;
            if (provider.error == null) {
              AppSnackbar.show(
                context,
                message: !isActive
                    ? 'Technicien reactive avec succes.'
                    : 'Technicien desactive avec succes.',
                isError: false,
              );
            }
          },
        );
      case _AdminSection.stats:
        return AdminStatisticsPage(
          tickets: provider.tickets,
          stats: provider.stats,
        );
    }
  }

  void _showReportPreview(TicketProvider provider) {
    final stats = provider.stats;
    final total = (stats['total_tickets'] as num?)?.toInt() ?? provider.tickets.length;
    final open = (stats['open_tickets'] as num?)?.toInt() ??
        provider.tickets.where((ticket) => ticket.statut == 'OUVERT').length;
    final inProgress = (stats['in_progress_tickets'] as num?)?.toInt() ??
        provider.tickets.where((ticket) => ticket.statut == 'EN_COURS').length;
    final resolved = (stats['resolved_tickets'] as num?)?.toInt() ??
        provider.tickets.where((ticket) => ticket.statut == 'RESOLU').length;
    final critical = (stats['critical_tickets'] as num?)?.toInt() ??
        provider.tickets.where((ticket) => ticket.priorite == 'CRITIQUE').length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rapport de pilotage'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Synthese dynamique basee sur les donnees actuellement chargees.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _reportLine('Tickets total', '$total'),
              _reportLine('Ouverts', '$open'),
              _reportLine('En cours', '$inProgress'),
              _reportLine('Resolus', '$resolved'),
              _reportLine('Critiques', '$critical'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _reportLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showTechnicianModal() {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 24, offset: Offset(0, 8))]), // Utilisation de AppColors.primary
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                child: Row(children: [
                  const Expanded(child: Text('Inscrire un Technicien', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.white)),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Consumer<AuthProvider>(builder: (context, auth, _) {
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        if (auth.error != null) ...[FeedbackBanner(message: auth.error!), const SizedBox(height: 16)],
                        _modalLabel('Nom complet *'),
                        const SizedBox(height: 6),
                        TextField(controller: _techFullNameCtrl, onChanged: (_) => auth.clearError(), decoration: _modalInput('Ex: Marc ISSA')),
                        const SizedBox(height: 16),
                        _modalLabel('Email Institutionnel *'),
                        const SizedBox(height: 6),
                        TextField(controller: _techEmailCtrl, onChanged: (_) => auth.clearError(), decoration: _modalInput('m.issa@univ-kara.tg')),
                        const SizedBox(height: 16),
                        _modalLabel('Téléphone (Optionnel)'),
                        const SizedBox(height: 6),
                        TextField(controller: _techPhoneCtrl, keyboardType: TextInputType.phone, decoration: _modalInput('Ex: 90 00 00 00')),
                        const SizedBox(height: 16),
                        _modalLabel('Mot de passe (Optionnel)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _techPasswordCtrl,
                          obscureText: !_isTechPasswordVisible,
                          decoration: _modalInput('Mot de passe personnalisé').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_isTechPasswordVisible ? Icons.visibility : Icons.visibility_off, color: const Color(0xFF9CA3AF)),
                              onPressed: () => setState(() => _isTechPasswordVisible = !_isTechPasswordVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBFDBFE))),
                          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(Icons.info, color: Color(0xFF3B82F6)),
                            SizedBox(width: 10),
                            Expanded(child: Text('Le système générera automatiquement un mot de passe sécurisé de 12 caractères et l\'enverra par email au technicien.', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 12, fontStyle: FontStyle.italic, height: 1.4))),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.loading ? null : _createTechnician,
                            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: auth.loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4)) : const Text('Enregistrer & Envoyer l\'invitation', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ]);
                    }),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _modalLabel(String text) => Text(text.toUpperCase(), style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8));

  InputDecoration _modalInput(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primaryColor, width: 2)),
    );
  }
}
