import 'package:flutter/material.dart';
import 'package:quicksale_pos/models/cliente_model.dart';
import 'package:quicksale_pos/models/user.dart';
import 'package:quicksale_pos/screens/select_client_screen.dart';
import '../helpers/database_helper.dart';
import '../helpers/currency_formatter.dart';
import '../models/product.dart';
import './scanner_screen.dart';
import '../widgets/empty_state.dart';

class SalesScreen extends StatefulWidget {
  final User user;
  const SalesScreen({super.key, required this.user});

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Venta'),
        content: const Text('¿Cómo desea finalizar la venta?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _processPaidSale();
            },
            child: const Text('Venta Pagada'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _processCreditSale();
            },
            child: const Text('Añadir a Deuda (Fiar)'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPaidSale() async {
    await dbHelper.createSale(_cart, widget.user.id!);
    setState(() {
      _cart.clear();
    });
    _showSnackBar('¡Venta finalizada con éxito!', isError: false);
  }

  Future<void> _processCreditSale() async {
    final selectedCliente = await Navigator.of(context).push<Cliente>(
      MaterialPageRoute(builder: (context) => const SelectClientScreen()),
    );

    if (selectedCliente != null) {
      final totalSale = _total;
      final updatedCliente = Cliente(
        id: selectedCliente.id,
        nombre: selectedCliente.nombre,
        telefono: selectedCliente.telefono,
        deudaActual: selectedCliente.deudaActual + totalSale,
      );

      await dbHelper.updateCliente(updatedCliente);
      await dbHelper.createSale(_cart, widget.user.id!, clienteId: selectedCliente.id);

      setState(() {
        _cart.clear();
      });

      _showSnackBar(
        'Deuda añadida a ${selectedCliente.nombre} con éxito.',
        isError: false,
      );
    }
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
                          CurrencyFormatter.format(product.price * quantity),
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
                        CurrencyFormatter.format(_total),
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
