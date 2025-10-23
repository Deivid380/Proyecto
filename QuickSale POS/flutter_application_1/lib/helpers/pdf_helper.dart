
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/sale.dart';

class PdfHelper {
  static Future<Uint8List> generateTicket(Sale sale, List<Map<String, dynamic>> saleDetails) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('Recibo de Venta', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Venta #${sale.id}'),
              pw.Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}'),
              pw.SizedBox(height: 20),
              pw.Divider(),
              // Table Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('Cant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.Divider(),
              // Table Body
              ...saleDetails.map((item) {
                final double totalItem = item['price'] * item['quantity'];
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(flex: 3, child: pw.Text(item['name'])),
                    pw.Expanded(flex: 1, child: pw.Text(item['quantity'].toString())),
                    pw.Expanded(flex: 2, child: pw.Text('\$${totalItem.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                  ],
                );
              }).toList(),
              pw.Divider(),
              pw.SizedBox(height: 20),
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.SizedBox(width: 10),
                  pw.Text('\$${sale.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
