import 'package:flutter/material.dart';

class FeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const FeedbackBanner({
    super.key,
    required this.message,
    this.isError = true,
  });

  @override
  Widget build(BuildContext context) {
    final background = isError ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF3);
    final border = isError ? const Color(0xFFFDA4AF) : const Color(0xFF86EFAC);
    final foreground = isError ? const Color(0xFFBE123C) : const Color(0xFF166534);
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
