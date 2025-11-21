import 'package:flutter/material.dart';
import 'package:quicksale_pos/helpers/currency_formatter.dart';
import 'package:quicksale_pos/helpers/database_helper.dart';
import '../models/sale.dart';
import '../widgets/empty_state.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SaleDetailScreen extends StatefulWidget {
  final Sale sale;
  const SaleDetailScreen({super.key, required this.sale});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late Future<List<Map<String, dynamic>>> _saleItemsFuture;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _saleItemsFuture = dbHelper.getSaleDetails(widget.sale.id!);
  }

  Future<void> _generateAndShowReceipt(List<Map<String, dynamic>> items) async {
    final doc = pw.Document();
    final saleDate = widget.sale.date;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('QuickSale POS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.SizedBox(height: 10),
              pw.Text('Recibo N°: ${widget.sale.id}'),
              pw.Text('Fecha: ${saleDate.toLocal().toString().split(' ')[0]}'),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 5), child: pw.Divider()),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('Cant.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 1, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.Divider(),
              ...items.map((item) {
                print('PDF Item: $item'); // Debug print - KEEP THIS
                final String productName = item['productName']?.toString() ?? 'Producto Desconocido';
                final int quantity = (item['quantity'] as int?) ?? 0;
                final double price = (item['price'] as double?) ?? 0.0;
                final double totalItem = price * quantity;
                return pw.Text('$productName x$quantity @ ${CurrencyFormatter.format(price)} = ${CurrencyFormatter.format(totalItem)}');
              }),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 5), child: pw.Divider()),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text(CurrencyFormatter.format(widget.sale.totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ]
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('¡Gracias por su compra!')),
            ]
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Venta #${widget.sale.id}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _saleItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'No se encontraron detalles para esta venta.',
            );
          }

          final items = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 24),
                Text(
                  'Artículos Vendidos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final double price = item['price'] as double;
                    final int quantity = item['quantity'] as int;
                    final totalItem = price * quantity;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(item['productName'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Cantidad: $quantity'),
                        trailing: Text(
                          CurrencyFormatter.format(totalItem),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<List<Map<String, dynamic>>>(
        future: _saleItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return FloatingActionButton.extended(
              onPressed: () => _generateAndShowReceipt(snapshot.data!),
              label: const Text('Ver Recibo'),
              icon: const Icon(Icons.receipt_long),
            );
          }
          return const SizedBox.shrink();
        }
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Vendido:', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  CurrencyFormatter.format(widget.sale.totalAmount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text('Fecha: ${widget.sale.date.toLocal().toString().split(' ')[0]}'),
          ],
        ),
      ),
    );
  }
}