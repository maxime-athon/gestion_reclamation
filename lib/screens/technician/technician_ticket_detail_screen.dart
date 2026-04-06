import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/feedback_banner.dart';

class TechnicianTicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const TechnicianTicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TechnicianTicketDetailScreen> createState() => _TechnicianTicketDetailScreenState();
}

class _TechnicianTicketDetailScreenState extends State<TechnicianTicketDetailScreen> {
  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchTicketDetail(widget.ticketId);
    });
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final ticket = provider.selectedTicket;
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : ticket == null
                ? Center(child: Text(provider.error ?? 'Intervention introuvable'))
                : Column(
                    children: [
                      _buildTopBar(ticket),
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
                                      if (provider.error != null) ...[
                                        FeedbackBanner(message: provider.error!),
                                        const SizedBox(height: 16),
                                      ],
                                      _buildReporterCard(ticket),
                                      const SizedBox(height: 20),
                                      ..._buildMessages(ticket, currentUserId),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Compositeur placé ici pour éviter les erreurs de layout
                      if (ticket.statut != 'RESOLU' && ticket.statut != 'CLOS')
                        _buildComposer(ticket),
                    ],
                  ),
      ),
    );
  }

  Widget _buildTopBar(Ticket ticket) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Intervention #${ticket.numeroTicket}',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: .3),
                ),
                const SizedBox(height: 2),
                Text(
                  'Priorite : ${_priorityLabel(ticket.priorite)}'.toUpperCase(),
                  style: TextStyle(color: _priorityAccent(ticket.priorite), fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildActionButton(
                label: 'EN COURS',
                color: const Color(0xFFF97316),
                onTap: () async {
                  await context.read<TicketProvider>().updateStatut(ticket.id, 'EN_COURS');
                  if (!mounted) return;
                  await context.read<TicketProvider>().fetchTicketDetail(ticket.id);
                },
              ),
              _buildActionButton(
                label: 'RESOLU',
                color: const Color(0xFF16A34A),
                onTap: () async {
                  await context.read<TicketProvider>().updateStatut(ticket.id, 'RESOLU');
                  if (!mounted) return;
                  await context.read<TicketProvider>().fetchTicketDetail(ticket.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .4)),
      ),
    );
  }

  Widget _buildReporterCard(Ticket ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
        border: const Border(left: BorderSide(color: Color(0xFF3B82F6), width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(
                'Signalement de : ${ticket.auteurNom}',
                style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${ticket.description}"',
            style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMessages(Ticket ticket, int? currentUserId) {
    if (ticket.commentaires.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Text(
            'Aucun echange pour le moment. Repondez au citoyen depuis le champ du bas.',
            style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
          ),
        ),
      ];
    }

    return ticket.commentaires.map((comment) {
      final isCurrentUser = currentUserId != null && comment.authorId == currentUserId;
      final authorName = comment.authorName.isNotEmpty ? comment.authorName : (isCurrentUser ? 'Technicien' : 'Citoyen');
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _messageBubble(
          initials: _initials(authorName),
          avatarColor: isCurrentUser ? AppColors.primaryDark : Colors.white,
          avatarTextColor: isCurrentUser ? Colors.white : const Color(0xFF6B7280),
          bubbleColor: isCurrentUser ? AppColors.primaryDark : Colors.white,
          textColor: isCurrentUser ? Colors.white : const Color(0xFF1F2937),
          timeColor: isCurrentUser ? const Color(0xFFA7F3D0) : const Color(0xFF9CA3AF),
          alignRight: isCurrentUser,
          message: comment.content,
          time: _time(comment.createdAt),
          border: isCurrentUser ? null : Border.all(color: const Color(0xFFF3F4F6)),
        ),
      );
    }).toList();
  }

  Widget _messageBubble({
    required String initials,
    required Color avatarColor,
    required Color avatarTextColor,
    required Color bubbleColor,
    required Color textColor,
    required Color timeColor,
    required bool alignRight,
    required String message,
    required String time,
    BoxBorder? border,
  }) {
    final borderRadius = alignRight
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(8),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: alignRight ? TextDirection.rtl : TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
                border: alignRight ? null : Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Text(initials, style: TextStyle(color: avatarTextColor, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                  border: border,
                  boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(message, style: TextStyle(color: textColor, fontSize: 14, height: 1.45)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(time, style: TextStyle(color: timeColor, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(Ticket ticket) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Row(
            children: [
              IconButton(
                onPressed: () => AppSnackbar.show(context, message: 'Fonctionnalite media bientot disponible.', isError: false),
                icon: const Icon(Icons.image),
                color: const Color(0xFF9CA3AF),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(18)),
                  child: TextField(
                    controller: _replyCtrl,
                    decoration: const InputDecoration(hintText: 'Repondre au citoyen...', border: InputBorder.none),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendReply(ticket),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _sendReply(ticket),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x22006743), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendReply(Ticket ticket) async {
    final message = _replyCtrl.text.trim();
    if (message.isEmpty) return;

    final provider = context.read<TicketProvider>();
    await provider.addComment(ticket.id, message);
    if (!mounted) return;
    if (provider.error == null) {
      _replyCtrl.clear();
      AppSnackbar.show(context, message: 'Reponse envoyee au citoyen.', isError: false);
    }
  }

  String _priorityLabel(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITIQUE': return 'Critique';
      case 'HAUTE': return 'Haute';
      case 'NORMALE': return 'Normale';
      default: return 'Basse';
    }
  }

  Color _priorityAccent(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITIQUE':
      case 'HAUTE': return const Color(0xFFFCA5A5);
      case 'NORMALE': return const Color(0xFFBFDBFE);
      default: return const Color(0xFFA7F3D0);
    }
  }

  String _time(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '--:--';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'TK';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
