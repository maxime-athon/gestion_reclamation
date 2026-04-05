import 'package:flutter/material.dart';

//ce fichier contient une classe AppSnackbar qui fournit une méthode statique show pour afficher des SnackBars personnalisés dans l'application. La méthode prend un contexte BuildContext, un message à afficher et un indicateur booléen isError pour déterminer la couleur de fond du SnackBar (rouge pour les erreurs et vert pour les succès). Le SnackBar est configuré pour être flottant, avec une marge et une forme arrondie pour une meilleure apparence visuelle.
class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = true,
  }) {
    final background = isError ? const Color(0xFF7F1D1D) : const Color(0xFF166534);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }
}
