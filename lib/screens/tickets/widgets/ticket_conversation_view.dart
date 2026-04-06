import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/ticket.dart';

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

  factory _ConversationEntry.system(String message) =>
      _ConversationEntry._(type: _ConversationType.system, message: message);

  factory _ConversationEntry.agent({required String initials, required String message, required String time}) =>
      _ConversationEntry._(type: _ConversationType.agent, message: message, initials: initials, time: time);

  factory _ConversationEntry.user({required String initials, required String message, required String time}) =>
      _ConversationEntry._(type: _ConversationType.user, message: message, initials: initials, time: time);
}

class TicketConversationView extends StatelessWidget {
  final Ticket ticket;
  final int? currentUserId;

  const TicketConversationView({
    super.key,
    required this.ticket,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final entries = _parseConversation();

    if (entries.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: entries.map(_buildEntryWidget).toList(),
    );
  }

  List<_ConversationEntry> _parseConversation() {
    final entries = <_ConversationEntry>[];

    if (ticket.assigneA != null && ticket.assigneA!.trim().isNotEmpty) {
      entries.add(_ConversationEntry.system('Le technicien "${ticket.assigneA}" a pris en charge le ticket'));
    }

    for (final comment in ticket.commentaires) {
      final isCurrentUser = currentUserId != null && comment.authorId == currentUserId;
      final initials = _getInitials(comment.authorName.isNotEmpty ? comment.authorName : (isCurrentUser ? 'Moi' : 'Support'));
      final time = _formatTime(comment.createdAt);

      if (isCurrentUser) {
        entries.add(_ConversationEntry.user(initials: initials, message: comment.content, time: time));
      } else {
        entries.add(_ConversationEntry.agent(initials: initials, message: comment.content, time: time));
      }
    }
    return entries;
  }

  Widget _buildEntryWidget(_ConversationEntry entry) {
    if (entry.type == _ConversationType.system) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(999)),
            child: Text(entry.message, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
          ),
        ),
      );
    }

    final isUser = entry.type == _ConversationType.user;
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
              CircleAvatar(
                radius: 16,
                backgroundColor: isUser ? const Color(0xFFD1D5DB) : AppColors.primary,
                child: Text(entry.initials, style: TextStyle(color: isUser ? const Color(0xFF4B5563) : Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: _getBorderRadius(isUser),
                    boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.message, style: TextStyle(fontSize: 14, height: 1.45, color: isUser ? Colors.white : const Color(0xFF1F2937))),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(entry.time, style: TextStyle(fontSize: 9, color: isUser ? const Color(0xFFA7F3D0) : const Color(0xFF9CA3AF))),
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
  }

  BorderRadius _getBorderRadius(bool isUser) {
    return isUser
        ? const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(6))
        : const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20));
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: const Text('Aucun commentaire pour le moment. Utilisez le champ ci-dessous pour lancer l\'échange.', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
    );
  }

  String _formatTime(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return '--:--';
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'TK';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length < 2 ? parts.first.length : 2).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}