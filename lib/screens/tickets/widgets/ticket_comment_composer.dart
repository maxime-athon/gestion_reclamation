import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../providers/ticket_provider.dart';

class TicketCommentComposer extends StatefulWidget {
  final int ticketId;

  const TicketCommentComposer({super.key, required this.ticketId});

  @override
  State<TicketCommentComposer> createState() => _TicketCommentComposerState();
}

class _TicketCommentComposerState extends State<TicketCommentComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final provider = context.read<TicketProvider>();
    await provider.addComment(widget.ticketId, message);
    if (mounted && provider.error == null) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.attach_file, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _submit,
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}