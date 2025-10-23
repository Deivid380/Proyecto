import 'package:flutter/material.dart';
import 'package:quicksale_pos/models/user.dart';
import 'package:quicksale_pos/screens/login_screen.dart';
import 'package:quicksale_pos/screens/user_management_screen.dart';

class ProfileScreen extends StatelessWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  void _logout(BuildContext context) {
    // Navega a la pantalla de login y elimina todas las rutas anteriores
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  String _getRoleInSpanish(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'vendedor':
        return 'Vendedor';
      case 'repartidor':
        return 'Repartidor';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              _getRoleInSpanish(user.role),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const Divider(height: 40),
          if (user.role == 'admin')
            ListTile(
              leading: const Icon(Icons.people_alt_outlined),
              title: const Text('Gestionar Usuarios'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
