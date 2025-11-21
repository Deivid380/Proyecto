import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:quicksale_pos/theme/app_theme.dart';
import '../helpers/database_helper.dart';
import '../helpers/currency_formatter.dart';
import '../models/product.dart';
import '../widgets/empty_state.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  void _showBarcodeDialog(Product product) {
    if (product.barcode == null || product.barcode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Este producto no tiene un código de barras asignado.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        final barcode = Barcode.code128();
        const double width = 200;
        const double height = 80;

        return AlertDialog(
          title: const Text('Código de Barras'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              BarcodeWidget(
                barcode: barcode,
                data: product.barcode!,
                width: width,
                height: height,
                drawText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () => _printBarcode(product, barcode, width, height),
              child: const Text('Imprimir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printBarcode(Product product, Barcode barcode, double width, double height) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(product.name, style: const pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 20),
                pw.BarcodeWidget(
                  barcode: barcode,
                  data: product.barcode!,
                  width: width,
                  height: height,
                  textStyle: const pw.TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
  }

  void _confirmAndDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar el producto "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('Delete cancelled for product: ${product.name}');
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog
              debugPrint('Attempting to delete product: ${product.name} (ID: ${product.id})');
              await dbHelper.deleteProduct(product.id!);
              debugPrint('Product deleted: ${product.name}');
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} eliminado')),
              );
              _refreshProducts();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme.gradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Productos'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
                // Temporarily disable Dismissible for debugging the delete button
                // return Dismissible(
                //   key: Key(product.id.toString()),
                //   direction: DismissDirection.endToStart,
                //   background: Container(
                //     color: Colors.red,
                //     alignment: Alignment.centerRight,
                //     padding: const EdgeInsets.symmetric(horizontal: 20),
                //     child: const Icon(Icons.delete, color: Colors.white),
                //   ),
                //   onDismissed: (direction) async {
                //     await dbHelper.deleteProduct(product.id!);
                //     if (!mounted) return;
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       SnackBar(content: Text('${product.name} eliminado')),
                //     );
                //     _refreshProducts();
                //   },
                //   child: Card(
                //     elevation: 1,
                //     margin: const EdgeInsets.symmetric(
                //       vertical: 4,
                //       horizontal: 8,
                //     ),
                //     child: ListTile(
                //       leading: CircleAvatar(
                //         backgroundImage: product.imageUrl != null
                //             ? FileImage(File(product.imageUrl!))
                //             : null,
                //         child: product.imageUrl == null
                //             ? const Icon(Icons.shopping_cart)
                //             : null,
                //       ),
                //       title: Text(
                //         product.name,
                //         style: const TextStyle(fontWeight: FontWeight.bold),
                //       ),
                //       subtitle: Text(
                //         'Stock: ${product.stock} | Código: ${product.barcode ?? 'N/A'}',
                //       ),
                //       trailing: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           Text(CurrencyFormatter.format(product.price)),
                //           IconButton(
                //             icon: const Icon(Icons.qr_code_2_rounded),
                //             onPressed: () => _showBarcodeDialog(product),
                //             tooltip: 'Ver Código de Barras',
                //           ),
                //           IconButton(
                //             icon: const Icon(Icons.delete_outline, color: Colors.red),
                //             onPressed: () => _confirmAndDeleteProduct(product),
                //             tooltip: 'Eliminar Producto',
                //           ),
                //         ],
                //       ),
                //       onTap: () => _showAddProductDialog(product: product),
                //     ),
                //   ),
                // );
                return Card(
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(CurrencyFormatter.format(product.price)),
                        IconButton(
                          icon: const Icon(Icons.qr_code_2_rounded),
                          onPressed: () => _showBarcodeDialog(product),
                          tooltip: 'Ver Código de Barras',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmAndDeleteProduct(product),
                          tooltip: 'Eliminar Producto',
                        ),
                      ],
                    ),
                    onTap: () => _showAddProductDialog(product: product),
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

  void _generateBarcode() {
    // Genera un código de barras único basado en el timestamp
    final barcode = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _barcodeController.text = barcode;
    });
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Código de barras',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino_rounded),
                onPressed: _generateBarcode,
                tooltip: 'Generar código',
              )
            ],
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
                  
                  // Asegurarse de que el código de barras no esté vacío
                  var barcode = _barcodeController.text;
                  if (barcode.isEmpty) {
                    barcode = DateTime.now().millisecondsSinceEpoch.toString();
                  }

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
                      barcode: barcode,
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
