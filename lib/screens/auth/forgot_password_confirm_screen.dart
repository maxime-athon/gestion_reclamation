import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/feedback_banner.dart';
import 'login_screen.dart';

// écran de confirmation de réinitialisation de mot de passe qui permet à l'utilisateur de saisir le code reçu par email et son nouveau mot de passe pour valider la réinitialisation
// L'écran est conçu pour être simple et clair, avec des champs de saisie pour le code de validation et le nouveau mot de passe, ainsi qu'un bouton de confirmation qui déclenche la validation auprès du backend via l'AuthProvider
class ForgotPasswordConfirmScreen extends StatefulWidget {
  const ForgotPasswordConfirmScreen({super.key});

  @override
  State<ForgotPasswordConfirmScreen> createState() => _ForgotPasswordConfirmScreenState();
}

class _ForgotPasswordConfirmScreenState extends State<ForgotPasswordConfirmScreen> {
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final token = _tokenCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (token.isEmpty || password.isEmpty) {
      AppSnackbar.show(context, message: 'Veuillez remplir tous les champs.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPasswordConfirm(token, password);

    if (!mounted) return;
    if (success) {
      AppSnackbar.show(context, message: 'Mot de passe réinitialisé. Connectez-vous.', isError: false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Confirmation',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Saisissez le code reçu par email et votre nouveau mot de passe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 20),
                    FeedbackBanner(message: auth.error!),
                  ],
                  const SizedBox(height: 32),
                  TextField(
                    controller: _tokenCtrl,
                    decoration: InputDecoration(
                      labelText: 'Code de validation',
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.loading ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: auth.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
