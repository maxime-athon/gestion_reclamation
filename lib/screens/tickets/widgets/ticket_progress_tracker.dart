import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class TicketProgressTracker extends StatelessWidget {
  final String status;

  const TicketProgressTracker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final currentStep = switch (normalized) {
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
    const primary = AppColors.primary;
    return SizedBox(
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showLine)
            Positioned(
              top: 15,
              left: 48,
              right: -8,
              child: Container(
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
                  boxShadow: highlighted ? [BoxShadow(color: primary.withOpacity(0.2), spreadRadius: 4)] : null,
                ),
                child: Icon(icon, size: 16, color: active ? Colors.white : const Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? primary : const Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }
}
