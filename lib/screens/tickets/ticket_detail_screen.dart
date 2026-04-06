import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/feedback_banner.dart';
import '../../widgets/app_snackbar.dart';
import 'widgets/ticket_progress_tracker.dart';
import 'widgets/ticket_status_badge.dart';
import 'widgets/ticket_detail_header.dart';
import 'widgets/ticket_comment_composer.dart';
import 'widgets/ticket_conversation_view.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchTicketDetail(widget.ticketId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final authRole = context.watch<AuthProvider>().userRole;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      // Important pour éviter que le clavier ne pousse les snackbars hors écran
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : (provider.error != null && provider.selectedTicket == null)
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: FeedbackBanner(message: provider.error!),
                  )
                : provider.selectedTicket == null
                    ? const Center(child: Text('Ticket introuvable'))
                    : _buildContent(provider, provider.selectedTicket!, authRole),
      ),
    );
  }

  Widget _buildContent(
    TicketProvider provider,
    Ticket ticket,
    String? authRole,
  ) {
    final currentUser = context.read<AuthProvider>().currentUser;

    return Column(
      children: [
        // Header fixe en haut
        TicketDetailHeader(ticket: ticket),
        
        // Zone de contenu scrollable
        Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TicketProgressTracker(status: ticket.statut),
                        const SizedBox(height: 24),
                        _buildAssignedTechCard(ticket),
                        const SizedBox(height: 16),
                        _buildDescriptionCard(ticket),
                        const SizedBox(height: 24),
                        TicketConversationView(
                          ticket: ticket,
                          currentUserId: currentUser?.id,
                        ),
                        if (_shouldShowRoleActions(ticket, authRole)) ...[
                          const SizedBox(height: 24),
                          _buildRoleActions(provider, ticket, authRole),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Zone de saisie fixe en bas (si ticket non clos)
        if (ticket.statut != 'CLOS')
          TicketCommentComposer(ticketId: ticket.id),
      ],
    );
  }

  Widget _buildAssignedTechCard(Ticket ticket) {
    if (ticket.assigneA == null || ticket.assigneA!.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.engineering, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Technicien assigné : ${ticket.assigneA}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Ticket ticket) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: TicketStatusBadge(status: ticket.statut)),
              const SizedBox(width: 12),
              Text(
                _formatDateTime(ticket.dateCreation),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ticket.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowRoleActions(Ticket ticket, String? authRole) {
    final isTech = authRole == 'TECHNICIEN';
    final isAdmin = authRole == 'ADMIN';
    final isAssignedToMe = ticket.assigneA == context.read<AuthProvider>().currentUser?.fullName;
    return (isTech && (ticket.statut == 'OUVERT' || (ticket.statut == 'EN_COURS' && isAssignedToMe))) || isAdmin;
  }

  Widget _buildRoleActions(TicketProvider provider, Ticket ticket, String? authRole) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          if (authRole == 'TECHNICIEN' && ticket.statut == 'OUVERT')
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              onPressed: () async {
                await provider.updateStatut(ticket.id, 'EN_COURS');
                if (mounted) await provider.fetchTicketDetail(ticket.id);
              },
              child: const Text('Prendre en charge'),
            ),
          if (authRole == 'TECHNICIEN' && ticket.statut == 'EN_COURS')
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              onPressed: () async {
                await provider.updateStatut(ticket.id, 'RESOLU');
                if (mounted) {
                  await provider.fetchTicketDetail(ticket.id);
                  AppSnackbar.show(context, message: 'Le ticket a été marqué comme résolu', isError: false);
                }
              },
              child: const Text('Marquer comme résolu'),
            ),
          if (authRole == 'ADMIN')
            OutlinedButton(
              onPressed: () => _showAssignDialog(context, provider),
              child: const Text('Assigner à un technicien'),
            ),
          if (authRole == 'ADMIN' && (ticket.statut == 'RESOLU' || ticket.statut == 'CLOS'))
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                await provider.archiveTicket(ticket.id);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Archiver le ticket'),
            ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context, TicketProvider provider) {
    int? selectedTechId;
    provider.fetchTechnicians();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assigner un technicien'),
        content: SizedBox(
          width: double.maxFinite,
          child: Autocomplete<Map<String, dynamic>>(
            displayStringForOption: (option) => '${option['first_name']} ${option['last_name']} (${option['email']})',
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') return const Iterable<Map<String, dynamic>>.empty();
              return provider.technicians.where((tech) {
                final fullName = '${tech['first_name']} ${tech['last_name']}'.toLowerCase();
                return fullName.contains(textEditingValue.text.toLowerCase()) ||
                    tech['email'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (selection) => selectedTechId = selection['id'],
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Rechercher par nom ou email',
                  prefixIcon: Icon(Icons.search),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (selectedTechId != null) {
                await provider.assignTicket(widget.ticketId, selectedTechId!);
                if (mounted) await provider.fetchTicketDetail(widget.ticketId);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;
    return '${_twoDigits(parsed.day)}/${_twoDigits(parsed.month)}/${parsed.year} - ${_twoDigits(parsed.hour)}:${_twoDigits(parsed.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
