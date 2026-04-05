import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/feedback_banner.dart';

// écran de création de ticket qui permet à l'utilisateur de soumettre une nouvelle demande d'assistance ou de signaler un incident

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _selectedType = 'INCIDENT';
  String _selectedPriority = 'NORMALE';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();

    if (title.isEmpty || description.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Veuillez remplir tous les champs obligatoires.',
      );
      return;
    }

    final provider = context.read<TicketProvider>();
    await provider.addTicket({
      'titre': title,
      'description': description,
      'type_ticket': _selectedType,
      'priorite': _selectedPriority,
    });

    if (!mounted) {
      return;
    }

    if (provider.error == null) {
      AppSnackbar.show(
        context,
        message: 'Votre ticket a bien été envoyé.',
        isError: false,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TicketProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (provider.error != null) ...[
                            FeedbackBanner(message: provider.error!),
                            const SizedBox(height: 20),
                          ],
                          const Text(
                            'Quel est le type de votre demande ?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildTypeOption(
                                value: 'INCIDENT',
                                label: 'Incident',
                                icon: Icons.warning,
                                color: const Color(0xFFF97316),
                              ),
                              const SizedBox(width: 12),
                              _buildTypeOption(
                                value: 'RECLAMATION',
                                label: 'Reclam.',
                                icon: Icons.campaign,
                                color: const Color(0xFFA855F7),
                              ),
                              const SizedBox(width: 12),
                              _buildTypeOption(
                                value: 'DEMANDE',
                                label: 'Demande',
                                icon: Icons.help_center,
                                color: const Color(0xFF3B82F6),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _buildFieldLabel('Objet du ticket'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _titleCtrl,
                            hintText: 'Ex: Panne de climatisation Salle A',
                            onChanged: (_) => context.read<TicketProvider>().clearError(),
                          ),
                          const SizedBox(height: 24),
                          _buildFieldLabel('Niveau d\'urgence'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            items: const [
                              DropdownMenuItem(
                                value: 'BASSE',
                                child: Text('Basse (Simple information)'),
                              ),
                              DropdownMenuItem(
                                value: 'NORMALE',
                                child: Text('Normale (Traitement standard)'),
                              ),
                              DropdownMenuItem(
                                value: 'HAUTE',
                                child: Text('Haute (Bloquant)'),
                              ),
                              DropdownMenuItem(
                                value: 'CRITIQUE',
                                child: Text('Critique (Urgence absolue)'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedPriority = value;
                              });
                              context.read<TicketProvider>().clearError();
                            },
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            decoration: _inputDecoration(),
                          ),
                          const SizedBox(height: 24),
                          _buildFieldLabel('Description detaillee'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _descriptionCtrl,
                            hintText: 'Decrivez le probleme avec precision...',
                            maxLines: 5,
                            onChanged: (_) => context.read<TicketProvider>().clearError(),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: provider.loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 10,
                                shadowColor: const Color(0x33006743),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: provider.loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.send),
                                        SizedBox(width: 8),
                                        Text(
                                          'Envoyer ma demande',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
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
              'Soumettre un ticket',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = value;
          });
          context.read<TicketProvider>().clearError();
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: _inputDecoration(hintText: hintText),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ), 
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ), 
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }
}
