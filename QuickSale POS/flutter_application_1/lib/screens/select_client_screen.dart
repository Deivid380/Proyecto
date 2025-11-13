import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/cliente_model.dart';

class SelectClientScreen extends StatefulWidget {
  const SelectClientScreen({super.key});

  @override
  State<SelectClientScreen> createState() => _SelectClientScreenState();
}

class _SelectClientScreenState extends State<SelectClientScreen> {
  late Future<List<Cliente>> _clientesFuture;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _clientesFuture = dbHelper.getAllClientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Cliente')),
      body: FutureBuilder<List<Cliente>>(
        future: _clientesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay clientes registrados.'));
          }
          final clientes = snapshot.data!;
          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return ListTile(
                title: Text(cliente.nombre),
                onTap: () {
                  Navigator.of(context).pop(cliente);
                },
              );
            },
          );
        },
      ),
    );
  }
}
