import 'dart:io';
import 'package:flutter/material.dart';
import 'package:quicksale_pos/models/user.dart';
import 'package:quicksale_pos/screens/scanner_screen.dart';
import '../helpers/database_helper.dart';
import '../helpers/currency_formatter.dart';
import '../models/product.dart';
import 'package:quicksale_pos/theme/app_theme.dart';
import 'package:quicksale_pos/widgets/empty_state.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:equatable/equatable.dart'; // Ensure this import is present

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
      print('Incrementing quantity for product ID: $productId');
      // Find the CartItem in _cart using productId
      final existingItemIndex = _cart.indexWhere((item) => item.product.id == productId);

      if (existingItemIndex == -1) {
        print('Error: Attempted to increment quantity for a product not in cart: $productId');
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
      print('Cart after incrementing: ${_cart.map((item) => '${item.product.name} x ${item.quantity}').join(', ')}');
      print('Current Cart Length: ${_cart.length}');
      print('Current Total: $_total');
    });
  }

  void _decrementQuantity(int productId) {
    setState(() {
      print('Decrementing quantity for product ID: $productId');
      // Find the CartItem in _cart using productId
      final existingItemIndex = _cart.indexWhere((item) => item.product.id == productId);

      if (existingItemIndex == -1) {
        print('Error: Attempted to decrement quantity for a product not in cart: $productId');
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
      print('Cart after decrementing: ${_cart.map((item) => '${item.product.name} x ${item.quantity}').join(', ')}');
      print('Current Cart Length: ${_cart.length}');
      print('Current Total: $_total');
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      print('Removing item from cart: ${item.product.name}');
      _cart = List<CartItem>.from(_cart)..remove(item); // Create new list and remove
      print('Cart after removing: ${_cart.map((item) => '${item.product.name} x ${item.quantity}').join(', ')}');
      print('Current Cart Length: ${_cart.length}');
      print('Current Total: $_total');
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

    // --- Pre-payment confirmation screen/dialog ---
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalles de la compra:'),
            ..._cart.map((item) => Text('${item.product.name} x ${item.quantity} - ${CurrencyFormatter.format(item.product.price * item.quantity)}')),
            const Divider(),
            Text('Total: ${CurrencyFormatter.format(_total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar Pago'),
          ),
        ],
      ),
    );

    if (confirmed == null || !confirmed) {
      return; // User cancelled payment
    }

    final saleId = await dbHelper.createSale(_cart, widget.user.id!);
    
    _generateAndPrintReceipt(saleId, _cart, _total);

    setState(() {
      _cart.clear();
    });
    _loadProducts(); // Recargar productos para reflejar el nuevo stock

    _showSuccessDialog();
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

  Future<void> _generateAndPrintReceipt(int saleId, List<CartItem> cart, double total) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('QuickSale POS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
              pw.SizedBox(height: 10),
              pw.Text('Recibo N°: $saleId'),
              pw.Text('Fecha: ${dateFormat.format(DateTime.now())}'),
              pw.Text('Atendido por: ${widget.user.username}'),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Divider(),
              ),
              pw.TableHelper.fromTextArray(
                headers: ['Producto', 'Cant.', 'Total'],
                data: cart.map((item) => [
                  item.product.name,
                  item.quantity.toString(),
                  CurrencyFormatter.format(item.product.price * item.quantity),
                ]).toList(),
                cellAlignment: pw.Alignment.centerRight,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 10),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3), // Producto
                  1: const pw.FlexColumnWidth(1), // Cant.
                  2: const pw.FlexColumnWidth(1.5), // Total
                },
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
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text('¡Gracias por su compra!')),
            ]
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
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
    super.key,
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
    print('BUILDING _CartView. Cart length: ${cart.length}');
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
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
                      print('  Building ListTile for ${item.product.name} x ${item.quantity}');
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