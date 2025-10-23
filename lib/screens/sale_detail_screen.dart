
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../helpers/database_helper.dart';
import '../helpers/pdf_helper.dart';
import '../models/sale.dart';

class SaleDetailScreen extends StatelessWidget {
  final Sale sale;
  final dbHelper = DatabaseHelper();

  SaleDetailScreen({super.key, required this.sale});

  Future<void> _printTicket() async {
    final saleDetails = await dbHelper.getSaleDetails(sale.id!);
    final pdfData = await PdfHelper.generateTicket(sale, saleDetails);
    await Printing.layoutPdf(onLayout: (format) async => pdfData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Venta #${sale.id}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Total: \${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: dbHelper.getSaleDetails(sale.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No se encontraron productos para esta venta.'));
                }

                final items = snapshot.data!;

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item['name']),
                      subtitle: Text('Cantidad: ${item['quantity']}'),
                      trailing: Text("\${(item['price'] * item['quantity']).toStringAsFixed(2)}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _printTicket,
        tooltip: 'Imprimir Ticket',
        child: const Icon(Icons.print),
      ),
    );
  }
}
