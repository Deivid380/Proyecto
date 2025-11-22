import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/cliente_model.dart';
import '../widgets/empty_state.dart';
import '../helpers/currency_formatter.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  late Future<List<Cliente>> _clientesFuture;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _refreshClientes();
  }

  void _refreshClientes() {
    setState(() {
      _clientesFuture = dbHelper.getAllClientes();
    });
  }

  void _showAddClienteDialog({Cliente? cliente}) {
    final nombreController = TextEditingController(text: cliente?.nombre);
    final telefonoController = TextEditingController(text: cliente?.telefono);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(cliente == null ? 'Añadir Cliente' : 'Editar Cliente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                autofocus: true,
              ),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono (Opcional)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreController.text;
                final telefono = telefonoController.text;

                if (nombre.isNotEmpty) {
                  final newCliente = Cliente(
                    id: cliente?.id,
                    nombre: nombre,
                    telefono: telefono.isNotEmpty ? telefono : null,
                    deudaActual: cliente?.deudaActual ?? 0.0,
                  );

                  if (cliente == null) {
                    await dbHelper.insertCliente(newCliente);
                  } else {
                    await dbHelper.updateCliente(newCliente);
                  }

                  if (!mounted) return; // Add this line here
                  Navigator.of(context).pop();
                  _refreshClientes();
                }
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
      appBar: AppBar(title: const Text('Clientes')),
      body: FutureBuilder<List<Cliente>>(
        future: _clientesFuture,
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
              message: 'No hay clientes. Añade uno para empezar.',
            );
          }

          final clientes = snapshot.data!;

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return ListTile(
                title: Text(cliente.nombre),
                subtitle: Text(cliente.telefono ?? 'Sin teléfono'),
                trailing: Text('Deuda: ${CurrencyFormatter.format(cliente.deudaActual)}'),
                onTap: () => _showAddClienteDialog(cliente: cliente),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClienteDialog(),
        tooltip: 'Añadir cliente',
        child: const Icon(Icons.add),
      ),
    );
  }
}
