// importations des packages nécessaires
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';

import '../providers/auth_provider.dart';
import 'admin/admin_dashboard_screen.dart';
import 'profile_screen.dart';
import 'technician/technician_dashboard_screen.dart';
import 'tickets/ticket_list_screen.dart';

// écran d'accueil qui affiche les différentes sections en fonction du rôle de l'utilisateur

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.userRole == 'ADMIN';
    final isTechnician = authProvider.userRole == 'TECHNICIEN';

    final currentScreens = <Widget>[
      isTechnician ? const TechnicianDashboardScreen() : const TicketListScreen(),
      if (isAdmin) const AdminDashboardScreen(),
      const ProfileScreen(),
    ];

    final currentItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(isTechnician ? Icons.engineering : Icons.list_alt),
        label: isTechnician ? 'Interventions' : 'Tickets',
      ),
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Admin',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];

    if (_selectedIndex >= currentScreens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: currentScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primary,
        items: currentItems,
      ),
    );
  }
}
