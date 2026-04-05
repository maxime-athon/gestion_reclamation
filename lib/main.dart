import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // On utilise MultiProvider pour injecter AuthProvider ET TicketProvider
    // au sommet de l'arbre des widgets.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
      ],
      child: MaterialApp(
        title: 'Gestion Réclamations',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Utilisation de la couleur verte définie dans vos écrans
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF006743),
            primary: const Color(0xFF006743),
          ),
          useMaterial3: true,
        ),
        home: const _AppBootstrap(),
      ),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late final Future<void> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = context.read<AuthProvider>().checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9FAFB),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006743),
              ),
            ),
          );
        }

        final authProvider = context.watch<AuthProvider>();
        return authProvider.isLoggedIn
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
