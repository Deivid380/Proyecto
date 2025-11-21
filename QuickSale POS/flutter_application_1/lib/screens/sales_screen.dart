import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:quicksale_pos/models/cliente_model.dart';
import 'package:quicksale_pos/models/user.dart';
import 'package:quicksale_pos/screens/select_client_screen.dart';
import '../helpers/database_helper.dart';
import '../helpers/currency_formatter.dart';
import '../models/product.dart';


// Modelo para representar un item en el carrito
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class SalesScreen extends StatefulWidget {
  final User user;
  const SalesScreen({super.key, required this.user});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final List<CartItem> _cart = [];
  final dbHelper = DatabaseHelper();

  // Camera and scanner state
  CameraController? _cameraController;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isScanning = false;
  String? _lastScannedCode;
  Timer? _scanResetTimer;

  double get _total =>
      _cart.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _scanResetTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      _cameraController!.startImageStream(_processCameraImage);
      setState(() {}); // To rebuild with camera preview
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isScanning) return;

    _isScanning = true;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isScanning = false;
      return;
    }

    try {
      final List<Barcode> barcodes =
          await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        final String? code = barcodes.first.rawValue;
        if (code != null && code != _lastScannedCode) {
          _lastScannedCode = code;
          _addProductFromBarcode(code);
          // Prevent re-scanning the same code immediately
          _scanResetTimer?.cancel();
          _scanResetTimer = Timer(const Duration(seconds: 2), () {
            _lastScannedCode = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      _isScanning = false;
    }
  }

  Future<void> _addProductFromBarcode(String code) async {
    final product = await dbHelper.getProductByBarcode(code);
    if (product != null) {
      if (product.stock > 0) {
        setState(() {
          final existingCartItemIndex =
              _cart.indexWhere((item) => item.product.id == product.id);

          if (existingCartItemIndex != -1) {
            // Solo incrementa si hay suficiente stock disponible
            if (_cart[existingCartItemIndex].quantity < product.stock) {
              _cart[existingCartItemIndex].quantity++;
            } else {
              _showSnackBar('No hay más stock disponible de ${product.name}.');
            }
          } else {
            _cart.add(CartItem(product: product));
          }
        });
      } else {
        _showSnackBar('Producto sin stock.');
      }
    } else {
      _showSnackBar('Producto no encontrado.');
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      final orientations = {
        services.DeviceOrientation.portraitUp: 0,
        services.DeviceOrientation.landscapeLeft: 90,
        services.DeviceOrientation.portraitDown: 180,
        services.DeviceOrientation.landscapeRight: 270,
      };
      var rotationCompensation =
          orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
      body: Column(
        children: [
          // Sección de Previsualización de la Cámara
          Expanded(
            flex: 2, // Adjust flex to give camera more or less space
            child: (_cameraController == null || !_cameraController!.value.isInitialized)
                ? const Center(child: CircularProgressIndicator())
                : ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width /
                              _cameraController!.value.aspectRatio,
                          child: CameraPreview(_cameraController!),
                        ),
                      ),
                    ),
                  ),
          ),
          // Cart Section
          Expanded( // Esta sección contendrá la lista del carrito y el botón de finalizar venta
            flex: 3, // Adjust flex to give cart more or less space
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return ListTile(
                              title: Text(item.product.name),
                              subtitle: Text('Cantidad: ${item.quantity}'),
                              trailing: Text(
                                CurrencyFormatter.format(
                                    item.product.price * item.quantity),
                              ),
                              onTap: () {
                                setState(() {
                                  _cart.removeAt(index);
                                });
                              },
                            );
                          },
                        ),
                ), // Fin del Expanded para la lista del carrito
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
                        mainAxisSize: MainAxisSize.min, // Para que la columna ocupe solo el espacio necesario
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
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 64, // Altura fija para el botón grande
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
          ),
        ],
      ),
    );
  }
}
