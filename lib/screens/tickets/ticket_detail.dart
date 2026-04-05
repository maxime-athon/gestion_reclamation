import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/ticket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/feedback_banner.dart';
import '../../widgets/app_snackbar.dart';

// écran de détail d'un ticket qui affiche les informations complètes du ticket, la conversation entre l'utilisateur et le technicien, 
//et les actions possibles en fonction du rôle de l'utilisateur et du statut du ticket
//il structure en plusieurs sections : un header avec le numéro et le titre du ticket, un tracker de progression, une description détaillée, une section de conversation, et une section d'actions pour les techniciens et les administrateurs

//classe charger de gérer l'affichage du détail d'un ticket, y compris la conversation et les actions possibles en fonction du rôle de l'utilisateur et du statut du ticket
class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

//état du TicketDetailScreen qui gère la logique d'affichage du détail d'un ticket, y compris la conversation et les actions possibles en fonction du rôle de l'utilisateur et du statut du ticket
class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchTicketDetail(widget.ticketId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();
    final authRole = context.watch<AuthProvider>().userRole;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        bottom: false,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: FeedbackBanner(message: provider.error!),
                  )
                : provider.selectedTicket == null
                    ? const Center(child: Text('Ticket introuvable'))
                    : _buildContent(provider, provider.selectedTicket!, authRole),
      ),
      bottomNavigationBar: (provider.selectedTicket == null || provider.selectedTicket!.statut == 'CLOS')
          ? null
          : _buildComposer(provider.selectedTicket!),
    );
  }

  Widget _buildContent(
    TicketProvider provider,
    Ticket ticket,
    String? authRole,
  ) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final conversation = _buildConversation(ticket, currentUser?.id);

    return Column(
      children: [
        _buildHeader(ticket),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressTracker(ticket),
                    const SizedBox(height: 24),
                    _buildAssignedTechCard(ticket),
                    const SizedBox(height: 16),
                    _buildDescriptionCard(ticket),
                    const SizedBox(height: 24),
                    if (conversation.isEmpty)
                      _buildEmptyConversation()
                    else
                      ..._buildConversationWidgets(conversation),
                    if (_shouldShowRoleActions(ticket, authRole)) ...[
                      const SizedBox(height: 24),
                      _buildRoleActions(provider, ticket, authRole),
                    ],
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Ticket ticket) {
    return Container(
      color: AppColors.primary,
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
                  'Ticket #${ticket.numeroTicket}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ticket.titre.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(Ticket ticket) {
    final status = ticket.statut.toUpperCase();
    final currentStep = switch (status) {
      'OUVERT' => 0,
      'EN_COURS' => 1,
      'RESOLU' || 'CLOS' => 2,
      _ => 0,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStep(
              label: 'Ouvert',
              icon: Icons.check,
              active: true,
              highlighted: currentStep == 0,
              showLine: true,
              lineActive: currentStep >= 1,
            ),
          ),
          Expanded(
            child: _buildStep(
              label: 'En cours',
              icon: Icons.engineering,
              active: currentStep >= 1,
              highlighted: currentStep == 1,
              showLine: true,
              lineActive: currentStep >= 2,
            ),
          ),
          Expanded(
            child: _buildStep(
              label: 'Resolue',
              icon: Icons.task_alt,
              active: currentStep >= 2,
              highlighted: currentStep == 2,
              showLine: false,
              lineActive: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String label,
    required IconData icon,
    required bool active,
    required bool highlighted,
    required bool showLine,
    required bool lineActive,
  }) {
    final primary = AppColors.primary;

    return SizedBox(
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showLine)
            Positioned(
              top: 15,
              left: 0,
              right: -8,
              child: Container(
                margin: const EdgeInsets.only(left: 48),
                height: 2,
                color: lineActive ? primary : const Color(0xFFE5E7EB),
              ),
            ),
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: active ? primary : const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                  boxShadow: highlighted
                      ? [
                          BoxShadow(
                            color: primary.withOpacity(0.2),
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: active ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? primary : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
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
              Expanded(child: _buildStatusBadge(ticket.statut)),
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

  Widget _buildStatusBadge(String status) {
    final normalized = status.toUpperCase();
    final badge = switch (normalized) {
      'OUVERT' => const _BadgeStyle(
          label: 'Ouvert',
          background: Color(0xFFDBEAFE),
          foreground: Color(0xFF1D4ED8),
        ),
      'EN_COURS' => const _BadgeStyle(
          label: 'En cours de traitement',
          background: Color(0xFFFFEDD5),
          foreground: Color(0xFFC2410C),
        ),
      'RESOLU' => const _BadgeStyle(
          label: 'Resolu',
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF15803D),
        ),
      'CLOS' => const _BadgeStyle(
          label: 'Cloture',
          background: Color(0xFFE5E7EB),
          foreground: Color(0xFF4B5563),
        ),
      _ => const _BadgeStyle(
          label: 'Statut inconnu',
          background: Color(0xFFE5E7EB),
          foreground: Color(0xFF4B5563),
        ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: badge.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          badge.label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
            color: badge.foreground,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyConversation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Aucun commentaire pour le moment. Utilisez le champ ci-dessous pour lancer l echange.',
        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
      ),
    );
  }

  List<_ConversationEntry> _buildConversation(Ticket ticket, int? currentUserId) {
    final entries = <_ConversationEntry>[];

    if (ticket.assigneA != null && ticket.assigneA!.trim().isNotEmpty) {
      entries.add(
        _ConversationEntry.system(
          'Le technicien "${ticket.assigneA}" a pris en charge le ticket',
        ),
      );
    }

    for (final comment in ticket.commentaires) {
      final isCurrentUser = currentUserId != null && comment.authorId == currentUserId;
      if (isCurrentUser) {
        entries.add(
          _ConversationEntry.user(
            initials: _initials(comment.authorName.isNotEmpty ? comment.authorName : 'Moi'),
            message: comment.content,
            time: _formatTime(comment.createdAt),
          ),
        );
      } else {
        entries.add(
          _ConversationEntry.agent(
            initials: _initials(comment.authorName.isNotEmpty ? comment.authorName : 'Support'),
            message: comment.content,
            time: _formatTime(comment.createdAt),
          ),
        );
      }
    }

    return entries;
  }

  List<Widget> _buildConversationWidgets(List<_ConversationEntry> entries) {
    return entries.map((entry) {
      if (entry.type == _ConversationType.system) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                entry.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.1,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        );
      }

      final isUser = entry.type == _ConversationType.user;
      final bubbleColor = isUser ? AppColors.primary : Colors.white;
      final textColor = isUser ? Colors.white : const Color(0xFF1F2937);
      final timeColor = isUser ? const Color(0xFFA7F3D0) : const Color(0xFF9CA3AF);
      final avatarColor = isUser ? const Color(0xFFD1D5DB) : AppColors.primary;
      final avatarTextColor = isUser ? const Color(0xFF4B5563) : Colors.white;
      final borderRadius = isUser
          ? const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            )
          : const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            );

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: isUser ? TextDirection.rtl : TextDirection.ltr,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    entry.initials,
                    style: TextStyle(
                      color: avatarTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: borderRadius,
                      border: isUser ? null : Border.all(color: const Color(0xFFF3F4F6)),
                      boxShadow: [
                        BoxShadow(
                          color: isUser ? AppColors.primary.withOpacity(0.1) : const Color(0x12000000),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.message,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: textColor,
                            fontStyle: isUser ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            entry.time,
                            style: TextStyle(fontSize: 9, color: timeColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
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
                if (mounted) {
                  await provider.fetchTicketDetail(ticket.id);
                }
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
              child: const Text('Assigner a un technicien'),
            ),
          if (authRole == 'ADMIN' && (ticket.statut == 'RESOLU' || ticket.statut == 'CLOS'))
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                await provider.archiveTicket(ticket.id);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Archiver le ticket'),
            ),
        ],
      ),
    );
  }

  Widget _buildComposer(Ticket ticket) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Row(
              children: [
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.attach_file),
                  color: const Color(0xFF9CA3AF),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _commentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitComment(ticket),
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _submitComment(ticket),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitComment(Ticket ticket) async {
    final message = _commentController.text.trim();
    if (message.isEmpty) {
      return;
    }

    final provider = context.read<TicketProvider>();
    await provider.addComment(ticket.id, message);
    if (!mounted) {
      return;
    }
    if (provider.error == null) {
      _commentController.clear();
    }
  }

  void _showAssignDialog(BuildContext context, TicketProvider provider) {
    int? selectedTechId;
    provider.fetchTechnicians();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assigner un technicien'),
        content: Autocomplete<Map<String, dynamic>>(
          displayStringForOption: (option) => '${option['first_name']} ${option['last_name']} (${option['email']})',
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<Map<String, dynamic>>.empty();
            }
            return provider.technicians.where((tech) {
              final fullName = '${tech['first_name']} ${tech['last_name']}'.toLowerCase();
              return fullName.contains(textEditingValue.text.toLowerCase()) ||
                  tech['email'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (selection) {
            selectedTechId = selection['id'];
          },
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedTechId != null) {
                await provider.assignTicket(widget.ticketId, selectedTechId!);
                if (context.mounted) {
                  await provider.fetchTicketDetail(widget.ticketId);
                }
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return raw;
    }

    return '${_twoDigits(parsed.day)}/${_twoDigits(parsed.month)}/${parsed.year} - ${_twoDigits(parsed.hour)}:${_twoDigits(parsed.minute)}';
  }

  String _formatTime(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return '--:--';
    }
    return '${_twoDigits(parsed.hour)}:${_twoDigits(parsed.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) {
      return 'TK';
    }
    if (parts.length == 1) {
      final end = parts.first.length < 2 ? parts.first.length : 2;
      return parts.first.substring(0, end).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _BadgeStyle {
  final String label;
  final Color background;
  final Color foreground;

  const _BadgeStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });
}

enum _ConversationType { system, agent, user }

class _ConversationEntry {
  final _ConversationType type;
  final String message;
  final String initials;
  final String time;

  const _ConversationEntry._({
    required this.type,
    required this.message,
    this.initials = '',
    this.time = '',
  });

  factory _ConversationEntry.system(String message) {
    return _ConversationEntry._(type: _ConversationType.system, message: message);
  }

  factory _ConversationEntry.agent({
    required String initials,
    required String message,
    required String time,
  }) {
    return _ConversationEntry._(
      type: _ConversationType.agent,
      message: message,
      initials: initials,
      time: time,
    );
  }

  factory _ConversationEntry.user({
    required String initials,
    required String message,
    required String time,
  }) {
    return _ConversationEntry._(
      type: _ConversationType.user,
      message: message,
      initials: initials,
      time: time,
    );
  }
}
