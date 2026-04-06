import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/feedback_banner.dart';
import '../tickets/ticket_detail_screen.dart';

// écran de notifications qui affiche les alertes et mises à jour liées aux tickets de l'utilisateur, avec des options pour marquer les notifications comme lues et accéder rapidement au détail des tickets concernés
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();

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
                onRefresh: () => context.read<TicketProvider>().fetchNotifications(), 
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    if (provider.error != null) ...[
                      FeedbackBanner(message: provider.error!),
                      const SizedBox(height: 16),
                    ],
                    if (provider.notificationsLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (provider.notifications.isEmpty)
                      _buildEmptyState()
                    else
                      ...provider.notifications.map(
                        (notification) => _buildNotificationTile(provider, notification),
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

  Widget _buildTopBar() {
    final unreadCount = context.watch<TicketProvider>().unreadNotificationsCount;

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
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: () => context.read<TicketProvider>().markAllNotificationsRead(),
              child: const Text(
                'Tout lire',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(TicketProvider provider, AppNotification notification) {
    final accent = _notificationColor(notification.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await provider.markNotificationRead(notification.id);
            }
            if (!mounted) {
              return;
            }
            if (notification.ticketId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailScreen(ticketId: notification.ticketId!),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.white : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: notification.isRead ? const Color(0xFFE5E7EB) : accent.withOpacity(.25),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_notificationIcon(notification.type), color: accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.message.isEmpty ? 'Vous avez recu une nouvelle notification.' : notification.message,
                        style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.45),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _formatDate(notification.createdAt),
                        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
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
      child: const Column(
        children: [
          Icon(Icons.notifications_off_outlined, size: 44, color: Color(0xFF9CA3AF)),
          SizedBox(height: 14),
          Text(
            'Aucune notification',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          ),
          SizedBox(height: 8),
          Text(
            'Les nouvelles alertes et mises a jour de tickets apparaitront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  IconData _notificationIcon(String type) {
    switch (type.toUpperCase()) {
      case 'COMMENT':
      case 'COMMENTAIRE':
      case 'MESSAGE':
        return Icons.chat_bubble_outline;
      case 'ASSIGNATION':
      case 'ASSIGNED':
        return Icons.assignment_ind_outlined;
      case 'STATUS':
      case 'STATUT':
        return Icons.track_changes_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _notificationColor(String type) {
    switch (type.toUpperCase()) {
      case 'COMMENT':
      case 'COMMENTAIRE':
      case 'MESSAGE':
        return const Color(0xFF3B82F6);
      case 'ASSIGNATION':
      case 'ASSIGNED':
        return const Color(0xFF8B5CF6);
      case 'STATUS':
      case 'STATUT':
        return const Color(0xFF16A34A);
      default: 
        return AppColors.primary;
    }
  }

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) {
      return 'Date inconnue';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} a $hour:$minute';
  }
}
