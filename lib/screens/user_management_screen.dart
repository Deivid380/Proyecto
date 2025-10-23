import 'package:flutter/material.dart';
import 'package:quicksale_pos/helpers/database_helper.dart';
import 'package:quicksale_pos/models/user.dart';
import 'package:quicksale_pos/widgets/empty_state.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final dbHelper = DatabaseHelper();
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = dbHelper.getAllUsers();
    });
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

  void _showUserDialog({User? user}) {
    final isEditing = user != null;
    final usernameController = TextEditingController(text: user?.username);
    final passwordController =
        TextEditingController(); // La contraseña siempre se pide de nuevo por seguridad

    // Mapea roles antiguos (inglés) a nuevos (español) para retrocompatibilidad
    String mapRoleToSpanish(String? role) {
      switch (role) {
        case 'seller':
          return 'vendedor';
        case 'delivery':
          return 'repartidor';
        default:
          return role ?? 'vendedor';
      }
    }

    String selectedRole = mapRoleToSpanish(user?.role);
    bool isBlocked = user?.status == 'blocked';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Usuario' : 'Añadir Usuario'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario',
                      ),
                      readOnly: isEditing, // No se puede cambiar el username
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: isEditing
                            ? 'Nueva contraseña (opcional)'
                            : 'Contraseña',
                      ),
                      obscureText: true,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items:
                          [
                                'admin',
                                'vendedor',
                                'repartidor',
                              ] // Roles disponibles
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(_getRoleInSpanish(role)),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRole = value;
                          });
                        }
                      },
                    ),
                    if (isEditing)
                      SwitchListTile(
                        title: const Text('Bloquear usuario'),
                        value: isBlocked,
                        onChanged: (value) {
                          setState(() {
                            isBlocked = value;
                          });
                        },
                        secondary: Icon(
                          isBlocked ? Icons.lock : Icons.lock_open,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = usernameController.text;
                final password = passwordController.text;

                if (username.isEmpty || (!isEditing && password.isEmpty)) {
                  // Validaciones básicas
                  return;
                }

                if (isEditing) {
                  final updatedUser = user.copyWith(
                    role: selectedRole,
                    status: isBlocked ? 'blocked' : 'active',
                    // Si se ingresó una nueva contraseña, se actualiza. Si no, se mantiene la anterior.
                    password: password.isNotEmpty ? password : user.password,
                  );
                  await dbHelper.updateUser(updatedUser);
                } else {
                  final newUser = User(
                    username: username,
                    password: password,
                    role: selectedRole,
                  );
                  await dbHelper.insertUser(newUser);
                }
                _refreshUsers();
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              message: 'No se encontraron usuarios.',
            );
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              // El admin no se puede editar ni borrar a sí mismo
              final bool isCurrentUserAdmin = user.username == 'admin';

              return Dismissible(
                key: Key(user.id.toString()),
                direction: isCurrentUserAdmin
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await dbHelper.deleteUser(user.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Usuario ${user.username} eliminado'),
                    ),
                  );
                  _refreshUsers();
                },
                child: Opacity(
                  opacity: user.status == 'blocked' ? 0.5 : 1.0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user.status == 'blocked'
                          ? Colors.grey
                          : Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      child: Icon(
                        isCurrentUserAdmin // Si es admin, usa este ícono
                            ? Icons.admin_panel_settings
                            : Icons.person_outline,
                      ),
                    ),
                    title: Text(user.username),
                    subtitle: Text(
                      'Rol: ${_getRoleInSpanish(user.role)} - Estado: ${user.status}',
                    ),
                    trailing: user.status == 'blocked'
                        ? const Icon(Icons.lock, color: Colors.orange)
                        : null,
                    onTap: isCurrentUserAdmin
                        ? null
                        : () => _showUserDialog(user: user),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        tooltip: 'Añadir Usuario',
        child: const Icon(Icons.add),
      ),
    );
  }
}
