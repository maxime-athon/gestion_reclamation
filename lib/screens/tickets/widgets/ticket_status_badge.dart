import 'package:flutter/material.dart';

class TicketStatusBadge extends StatelessWidget {
  final String status;

  const TicketStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final (label, background, foreground) = switch (normalized) {
      'OUVERT' => ('Ouvert', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)),
      'EN_COURS' => ('En cours de traitement', const Color(0xFFFFEDD5), const Color(0xFFC2410C)),
      'RESOLU' => ('Resolu', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'CLOS' => ('Cloture', const Color(0xFFE5E7EB), const Color(0xFF4B5563)),
      _ => ('Statut inconnu', const Color(0xFFE5E7EB), const Color(0xFF4B5563)),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
            color: foreground,
          ),
        ),
      ),
    );
  }
}