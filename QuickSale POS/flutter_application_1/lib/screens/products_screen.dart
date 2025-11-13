import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../helpers/database_helper.dart';
import '../helpers/currency_formatter.dart';
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Añadir Producto' : 'Editar Producto'),
          content: _AddProductForm(
            product: product,
            onSave: (newProduct) async {
              if (product == null) {
                await dbHelper.insertProduct(newProduct);
              } else {
                await dbHelper.updateProduct(newProduct);
              }
              _refreshProducts();
              Navigator.of(context).pop();
            },
          ),
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
                    leading: CircleAvatar(
                      backgroundImage: product.imageUrl != null
                          ? FileImage(File(product.imageUrl!))
                          : null,
                      child: product.imageUrl == null
                          ? const Icon(Icons.shopping_cart)
                          : null,
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Stock: ${product.stock} | Código: ${product.barcode ?? 'N/A'}',
                    ),
                    trailing: Text(CurrencyFormatter.format(product.price)),
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

class _AddProductForm extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const _AddProductForm({this.product, required this.onSave});

  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();
  XFile? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = CurrencyFormatter.format(widget.product!.price);
      _stockController.text = widget.product!.stock.toString();
      _barcodeController.text = widget.product!.barcode ?? '';
      _imageUrl = widget.product!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<String?> _saveImage(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = path.basename(image.path);
    final savedImage = await File(image.path).copy('${directory.path}/$fileName');
    return savedImage.path;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _imageFile != null
                  ? FileImage(File(_imageFile!.path))
                  : (_imageUrl != null ? FileImage(File(_imageUrl!)) : null),
              child: _imageFile == null && _imageUrl == null
                  ? const Icon(Icons.add_a_photo, size: 50)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
            autofocus: true,
          ),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Precio'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _stockController,
            decoration: const InputDecoration(labelText: 'Stock'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _barcodeController,
            decoration: const InputDecoration(
              labelText: 'Código de barras (Opcional)',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text;
                  final priceString =
                      _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
                  final price = double.tryParse(priceString) ?? 0.0;
                  final stock = int.tryParse(_stockController.text) ?? 0;
                  final barcode = _barcodeController.text;
                  String? imageUrl = _imageUrl;

                  if (_imageFile != null) {
                    imageUrl = await _saveImage(_imageFile!);
                  }

                  if (name.isNotEmpty) {
                    final newProduct = Product(
                      id: widget.product?.id,
                      name: name,
                      price: price,
                      stock: stock,
                      barcode: barcode.isNotEmpty ? barcode : null,
                      imageUrl: imageUrl,
                    );
                    widget.onSave(newProduct);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
