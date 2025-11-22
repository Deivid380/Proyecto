import 'package:flutter/material.dart';
import 'dart:io'; // For File

// Local project imports
import 'package:quicksale_pos/models/product.dart';
import 'package:quicksale_pos/models/user.dart';
import 'package:quicksale_pos/helpers/database_helper.dart';
import 'package:quicksale_pos/screens/scanner_screen.dart';
import 'package:quicksale_pos/helpers/currency_formatter.dart';
import 'package:quicksale_pos/theme/app_theme.dart';
import 'package:quicksale_pos/widgets/empty_state.dart';

// Package imports
import 'package:intl/intl.dart';
import 'package:equatable/equatable.dart'; // For Equatable
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';


// Modelo para representar un item en el carrito
class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

class SalesScreen extends StatefulWidget {
  final User user;
  const SalesScreen({super.key, required this.user});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final dbHelper = DatabaseHelper();
  List<Product> _products = [];
  List<CartItem> _cart = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // New controllers and variables for payment dialog
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  String? _selectedPaymentMethod;
  // End new controllers and variables


  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  List<Product> _filterProducts() {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products.where((product) =>
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (product.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  Future<void> _loadProducts() async {
    final products = await dbHelper.getAllProducts();
    setState(() {
      _products = products;
    });
  }

  void _handleProductTap(Product product) {
    setState(() {
      final existingItemIndex =
          _cart.indexWhere((item) => item.product.id == product.id);

      if (existingItemIndex != -1) {
        // Product is already in cart, decrement quantity or remove
        final CartItem existingItem = _cart[existingItemIndex];
        if (existingItem.quantity > 1) {
          _cart = _cart.map((itemInCart) {
            if (itemInCart.product.id == product.id) {
              return itemInCart.copyWith(quantity: itemInCart.quantity - 1);
            }
            return itemInCart;
          }).toList();
        } else {
          // Quantity is 1, remove from cart
          _cart = List<CartItem>.from(_cart)..removeWhere((itemInCart) => itemInCart.product.id == product.id);
        }
      } else {
        // Product not in cart, add it (only if stock > 0)
        final int currentStockInDb = product.stock; // Assuming product.stock is the total stock
        // Find existing quantity in cart for this product, defaulting to 0 if not present
        final int quantityInCart = _cart.firstWhere((item) => item.product.id == product.id, orElse: () => CartItem(product: Product(id: -1, name: '', price: 0.0, stock: 0), quantity: 0)).quantity;
        final int availableForSale = currentStockInDb - quantityInCart;


        if (availableForSale <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Este producto no tiene stock disponible.'),
            backgroundColor: Colors.orange,
          ));
          return; // Exit if no stock
        }
        _cart = [..._cart, CartItem(product: product)];
      }
    });
  }

  void _incrementQuantity(int productId) {
    setState(() {
      // Find the CartItem in _cart using productId
      final existingItemIndex = _cart.indexWhere((item) => item.product.id == productId);

      if (existingItemIndex == -1) {
        return;
      }

      final CartItem existingItem = _cart[existingItemIndex];
      final int currentStockInDb = existingItem.product.stock;

      final int quantityInCart = _cart.firstWhere((cartItem) => cartItem.product.id == productId, orElse: () => CartItem(product: Product(id: -1, name: '', price: 0.0, stock: 0), quantity: 0)).quantity;
      
      final int availableForIncrement = currentStockInDb - quantityInCart;

      if (availableForIncrement > 0) {
        _cart = _cart.map((cartItem) {
          if (cartItem.product.id == productId) {
            return cartItem.copyWith(quantity: existingItem.quantity + 1);
          }
          return cartItem;
        }).toList();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No hay más stock disponible para este producto.'),
            backgroundColor: Colors.orange,
          ));
      }
    });
  }

  void _decrementQuantity(int productId) {
    setState(() {
      // Find the CartItem in _cart using productId
      final existingItemIndex = _cart.indexWhere((item) => item.product.id == productId);

      if (existingItemIndex == -1) {
        return;
      }

      final CartItem existingItem = _cart[existingItemIndex];

      if (existingItem.quantity > 1) {
        _cart = _cart.map((cartItem) {
          if (cartItem.product.id == productId) { // Compare by product ID
            return cartItem.copyWith(quantity: existingItem.quantity - 1);
          }
          return cartItem;
        }).toList();
      } else {
        _removeFromCart(existingItem);
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      _cart = List<CartItem>.from(_cart)..remove(item); // Create new list and remove
    });
  }

  Future<void> _scanBarcode() async {
    final String? barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (barcode != null) {
      try {
        final product = _products.firstWhere((p) => p.barcode == barcode);
        _handleProductTap(product);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto con código "$barcode" no encontrado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePayment() async {
    if (_cart.isEmpty) return;

    // Reset controllers and selected method for a new transaction
    _clientNameController.clear();
    _clientPhoneController.clear();
    _selectedPaymentMethod = null;

    final _formKey = GlobalKey<FormState>();

    // --- Pre-payment confirmation screen/dialog ---
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Compra'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detalles de la compra:'),
                    ..._cart.map((item) => Text('${item.product.name} x ${item.quantity} - ${CurrencyFormatter.format(item.product.price * item.quantity)}')),
                    const Divider(),
                    Text('Total: ${CurrencyFormatter.format(_total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Cliente (Opcional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _clientPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono del Cliente (Opcional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: ['Efectivo', 'Tarjeta', 'Transferencia', 'Crédito']
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona un método de pago';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );

    if (confirmed == null || !confirmed) {
      return; // User cancelled payment or validation failed
    }

    // Processing animation/indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Procesando venta...'),
          ],
        ),
      ),
    );

    // Simulate network/database operation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.of(context).pop(); // Close processing dialog

    final clientName = _clientNameController.text.isNotEmpty ? _clientNameController.text : null;
    final clientPhone = _clientPhoneController.text.isNotEmpty ? _clientPhoneController.text : null;
    final paymentMethod = _selectedPaymentMethod; // This will not be null due to validation

    // --- DEBUG START ---
    print('DEBUG: Cart content before createSale: $_cart');
    // --- DEBUG END ---

    final saleId = await dbHelper.createSale(
        _cart,
        widget.user.id!,
        clientName: clientName,
        clientPhone: clientPhone,
        paymentMethod: paymentMethod,
    );
    
    if (!mounted) return;
    _generateAndPrintReceipt(saleId, _cart, _total, clientName, clientPhone, paymentMethod!);

    setState(() {
      _cart.clear();
      _clientNameController.clear();
      _clientPhoneController.clear();
      _selectedPaymentMethod = null;
    });
    _loadProducts(); // Recargar productos para reflejar el nuevo stock

    // Show success checkmark animation
    _showSuccessAnimation();
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text('¡Factura Generada!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close success animation
      _showSuccessDialog(); // Show the original success dialog
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Venta Completada'),
        content: const Text('La venta ha sido registrada y el stock actualizado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hecho'), // Changed from 'Aceptar' to 'Hecho'
          )
        ],
      ),
    );
  }

  Future<void> _generateAndPrintReceipt(int saleId, List<CartItem> cart, double total, String? clientName, String? clientPhone, String paymentMethod) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('QuickSale POS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, font: boldFont))),
              pw.SizedBox(height: 10),
              pw.Text('Recibo N°: $saleId', style: pw.TextStyle(font: font)),
              pw.Text('Fecha: ${dateFormat.format(DateTime.now())}', style: pw.TextStyle(font: font)),
              pw.Text('Atendido por: ${widget.user.username}', style: pw.TextStyle(font: font)),
              if (clientName != null && clientName.isNotEmpty) // New: Client Name
                pw.Text('Cliente: $clientName', style: pw.TextStyle(font: font)),
              if (clientPhone != null && clientPhone.isNotEmpty) // New: Client Phone
                pw.Text('Teléfono: $clientPhone', style: pw.TextStyle(font: font)),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Divider(),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont))),
                      pw.Expanded(flex: 1, child: pw.Text('Cant.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 1, child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: boldFont), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  pw.Divider(),
                  // Construir la lista de ítems de venta por separado
                  ..._buildPdfSaleItems(cart, font, boldFont),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Divider(),
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('TOTAL: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.Text(
                    CurrencyFormatter.format(total),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                  ),
                ]
              ),
              pw.SizedBox(height: 5), // Added spacing
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Método de Pago: $paymentMethod', style: pw.TextStyle(fontSize: 12)), // New: Payment Method
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

  List<pw.Widget> _buildPdfSaleItems(List<CartItem> cart, pw.Font font, pw.Font boldFont) {
    return cart.map((item) {
      final String productName = item.product.name.isNotEmpty ? item.product.name : 'Producto Desconocido';
      final int quantity = item.quantity;
      final double price = item.product.price;
      final double itemTotal = price * quantity;
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(productName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: boldFont)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cant: $quantity', style: pw.TextStyle(fontSize: 9, font: font)),
              pw.Text('Precio unit.: ${CurrencyFormatter.format(price)}', style: pw.TextStyle(fontSize: 9, font: font)),
              pw.Text('Total: ${CurrencyFormatter.format(itemTotal)}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, font: boldFont)),
            ],
          ),
          pw.SizedBox(height: 5), // Espacio entre ítems
        ],
      );
    }).toList();
  }

  double get _total => _cart.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));

  void _showCartModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the modal to take full height
      builder: (BuildContext context) {
        return FractionallySizedBox( // Take a fraction of the screen height
          heightFactor: 0.8, // Adjust as needed, e.g., 80% of screen height
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateInner) {
              return _CartView(
                cart: _cart,
                onIncrement: _incrementQuantity,
                onDecrement: _decrementQuantity,
                onRemove: _removeFromCart,
                onPay: () {
                  Navigator.pop(context); // Close the modal before payment
                  _handlePayment();
                },
                onRefresh: () {
                  setState(() {}); // Force rebuild of SalesScreen
                  setStateInner(() {}); // Force rebuild of StatefulBuilder's content
                },
                total: _total,
              );
            }
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme.gradientBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            FocusScope.of(context).unfocus(); // Dismiss keyboard
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.document_scanner_outlined),
                  onPressed: _scanBarcode,
                ),
              ],
            ),
            body: (constraints.maxWidth > 800)
                ? Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _ProductGrid(
                          products: _filterProducts(),
                          cart: _cart,
                          onToggleProductInCart: _handleProductTap,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: StatefulBuilder(
                          builder: (BuildContext context, StateSetter setStateInner) {
                            return _CartView(
                              cart: _cart,
                              onIncrement: _incrementQuantity,
                              onDecrement: _decrementQuantity,
                              onRemove: _removeFromCart,
                              onPay: _handlePayment,
                              onRefresh: () {
                                setState(() {}); // Force rebuild of SalesScreen
                                setStateInner(() {}); // Force rebuild of StatefulBuilder's content
                              },
                              total: _total,
                            );
                          }
                        ),
                      ),
                    ],
                  )
                : _ProductGrid(
                    products: _filterProducts(),
                    cart: _cart,
                    onToggleProductInCart: _handleProductTap,
                  ),
            floatingActionButton: (_cart.isNotEmpty && constraints.maxWidth <= 800)
                ? FloatingActionButton.extended(
                    onPressed: () {
                      _showCartModalBottomSheet(context);
                    },
                    label: Text('Ver Carrito (${_cart.length})'),
                    icon: const Icon(Icons.shopping_cart),
                  )
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final List<CartItem> cart;
  final void Function(Product) onToggleProductInCart;

  const _ProductGrid({
    required this.products,
    required this.cart,
    required this.onToggleProductInCart,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'No hay productos en el inventario.',
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final cartItem = cart.firstWhere(
          (item) => item.product.id == product.id,
          orElse: () => CartItem(product: Product(id: -1, name: '', price: 0.0, stock: 0), quantity: 0), // Use non-const CartItem
        );
        final availableStock = product.stock - cartItem.quantity;
        final isOutOfStock = availableStock <= 0;

        return Card(
          clipBehavior: Clip.antiAlias,
          color: isOutOfStock ? Colors.grey.shade300 : null,
          child: InkWell(
            onTap: isOutOfStock ? null : () => onToggleProductInCart(product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                      ? Image.file(
                          File(product.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isOutOfStock ? TextDecoration.lineThrough : null,
                      color: isOutOfStock ? Colors.grey.shade600 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    isOutOfStock ? 'Agotado' : 'Stock: $availableStock',
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : Colors.grey[600],
                      fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(bottom: 8.0),
                  child: Text(CurrencyFormatter.format(product.price), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartView extends StatelessWidget {
  final List<CartItem> cart;
  final Function(int) onIncrement;
  final Function(int) onDecrement;
  final Function(CartItem) onRemove;
  final VoidCallback onPay;
  final VoidCallback onRefresh; // New callback for manual refresh
  final double total;

  const _CartView({
    required this.cart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onPay,
    required this.onRefresh, // Required for manual refresh
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withAlpha(255 ~/ 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Carrito', style: Theme.of(context).textTheme.headlineSmall),
          ),
          const Divider(height: 1),
          Expanded(
            child: cart.isEmpty
                ? const EmptyState(icon: Icons.shopping_cart_outlined, message: 'El carrito está vacío')
                : ListView.builder(
                    key: ValueKey(cart.hashCode.toString()), // Aggressive rebuild key
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      final availableStockInProduct = item.product.stock - item.quantity; // Stock available for this product outside the cart
                      return ListTile(
                        key: ObjectKey(item),
                        leading: CircleAvatar(
                          backgroundImage: (item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty)
                              ? FileImage(File(item.product.imageUrl!))
                              : null,
                          child: (item.product.imageUrl == null || item.product.imageUrl!.isEmpty)
                              ? const Icon(Icons.shopping_cart)
                              : null,
                        ),
                        title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(CurrencyFormatter.format(item.product.price)),
                            Text('Stock disponible: ${availableStockInProduct < 0 ? 0 : availableStockInProduct}', style: TextStyle(color: availableStockInProduct <= 0 ? Colors.red : Colors.grey[600])),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => onDecrement(item.product.id!), iconSize: 20),
                            Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => onIncrement(item.product.id!), iconSize: 20),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => onRemove(item), iconSize: 22),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL', style: Theme.of(context).textTheme.titleLarge),
                    Text(CurrencyFormatter.format(total), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: cart.isEmpty ? null : onPay,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Pagar'),
                ),
                const SizedBox(height: 10), // Add some spacing
                ElevatedButton(
                  onPressed: cart.isEmpty ? null : onRefresh,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blueGrey, // Distinct color
                  ),
                  child: const Text('Actualizar Carrito', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}