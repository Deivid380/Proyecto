
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../widgets/empty_state.dart';

class TopProductsScreen extends StatelessWidget {
  const TopProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos Más Vendidos'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbHelper.getTopSellingProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.trending_down,
              message: 'No hay datos de ventas para mostrar.',
            );
          }

          final topProducts = snapshot.data!;

          return ListView.builder(
            itemCount: topProducts.length,
            itemBuilder: (context, index) {
              final product = topProducts[index];
              final rank = index + 1;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(rank.toString()),
                ),
                title: Text(product['name']),
                trailing: Text(
                  'Vendidos: ${product['total_quantity']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
