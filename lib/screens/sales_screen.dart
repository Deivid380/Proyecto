import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import './scanner_screen.dart';
import '../widgets/empty_state.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final List<Product> _cart = [];
  final dbHelper = DatabaseHelper();

  double get _total => _cart.fold(0, (sum, item) => sum + item.price);

  void _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (code != null) {
      final product = await dbHelper.getProductByBarcode(code);
      if (product != null) {
        if (product.stock > 0) {
          setState(() {
            _cart.add(product);
          });
        } else {
          _showSnackBar('Producto sin stock.');
        }
      } else {
        _showSnackBar('Producto no encontrado.');
      }
    }
  }

  void _finalizeSale() async {
    if (_cart.isEmpty) return;

    await dbHelper.createSale(_cart);

    setState(() {
      _cart.clear();
    });

    _showSnackBar('¡Venta finalizada con éxito!', isError: false);
  }

  void _removeItem(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group items for display
    final Map<int, Map<String, dynamic>> groupedCart = {};
    for (var product in _cart) {
      if (groupedCart.containsKey(product.id)) {
        groupedCart[product.id!]!['quantity']++;
      } else {
        groupedCart[product.id!] = {'product': product, 'quantity': 1};
      }
    }
    final groupedItems = groupedCart.values.toList();

    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      body: Column(
        children: [
          Expanded(
            child: _cart.isEmpty
                ? const EmptyState(
                    icon: Icons.qr_code_scanner_outlined,
                    message: 'Escanee un producto para comenzar',
                  )
                : ListView.builder(
                    itemCount: groupedItems.length,
                    itemBuilder: (context, index) {
                      final item = groupedItems[index];
                      final Product product = item['product'];
                      final int quantity = item['quantity'];

                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text('Cantidad: $quantity'),
                        trailing: Text(
                          currencyFormatter.format(product.price * quantity),
                        ),
                        onTap: () {
                          // Simple removal of first occurrence
                          setState(() {
                            _cart.remove(product);
                          });
                        },
                      );
                    },
                  ),
          ),
          Card(
            elevation: 4,
            margin: const EdgeInsets.all(0),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        currencyFormatter.format(_total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cart.isEmpty ? null : _finalizeSale,
                      child: const Text('Finalizar Venta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        tooltip: 'Escanear producto',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
