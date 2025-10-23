import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../widgets/empty_state.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Product>> _productsFuture;
  final dbHelper = DatabaseHelper();

  // Formateador para mostrar en la lista
  final listCurrencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  void _refreshProducts() {
    setState(() {
      _productsFuture = dbHelper.getAllProducts();
    });
  }

  void _showAddProductDialog({Product? product}) {
    // Formateador para la moneda colombiana (sin decimales, con punto de mil)
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '', // No necesitamos el símbolo '$' en el campo de texto
      decimalDigits: 0,
    );

    final nameController = TextEditingController(text: product?.name);
    final priceController = TextEditingController(
      text: product != null ? currencyFormatter.format(product.price) : '',
    );
    final stockController = TextEditingController(
      text: product?.stock.toString(),
    );
    final barcodeController = TextEditingController(text: product?.barcode);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Añadir Producto' : 'Editar Producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  autofocus: true,
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de barras (Opcional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text;
                // Limpiamos el formato de moneda (quitamos puntos) antes de convertir a número
                final priceString = priceController.text.replaceAll('.', '');
                final price = double.tryParse(priceString) ?? 0.0;
                final stock = int.tryParse(stockController.text) ?? 0;
                final barcode = barcodeController.text;

                if (name.isNotEmpty) {
                  final newProduct = Product(
                    id: product?.id,
                    name: name,
                    price: price,
                    stock: stock,
                    barcode: barcode.isNotEmpty ? barcode : null,
                  );

                  if (product == null) {
                    await dbHelper.insertProduct(newProduct);
                  } else {
                    await dbHelper.updateProduct(newProduct);
                  }
                  _refreshProducts();
                  Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('Productos')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No hay productos. Añade uno para empezar.',
            );
          }

          final products = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Dismissible(
                key: Key(product.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await dbHelper.deleteProduct(product.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} eliminado')),
                  );
                  _refreshProducts();
                },
                child: Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Stock: ${product.stock} | Código: ${product.barcode ?? 'N/A'}',
                    ),
                    trailing: Text(listCurrencyFormatter.format(product.price)),
                    onTap: () => _showAddProductDialog(product: product),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(),
        tooltip: 'Añadir producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}
