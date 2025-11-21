import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  bool _isScanning = false;
  String? _lastScannedCode;
  Timer? _scanResetTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
      if (!mounted) {
        return;
      }
      _cameraController!.startImageStream(_processCameraImage);
      setState(() {}); // To rebuild with camera preview
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isScanning) {
      return;
    }

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
          // Pop with the detected code
          if (!mounted) {
            return;
          }
          Navigator.of(context).pop(code);
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
      // Delay before allowing the next scan to avoid overwhelming the processor
      await Future.delayed(const Duration(milliseconds: 500));
      _isScanning = false;
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) {
      return null;
    }

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = _rotationIntToImageRotation(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) {
        return null;
      }
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = _rotationIntToImageRotation(rotationCompensation);
    }
    if (rotation == null) {
      return null;
    }

    // get image format
    InputImageFormat? format;
    if (image.format.group == ImageFormatGroup.yuv420) {
      format = InputImageFormat.yuv420;
    } else if (image.format.group == ImageFormatGroup.nv21) {
      format = InputImageFormat.nv21;
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      format = InputImageFormat.bgra8888;
    }
    if (format == null) {
      return null;
    }

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;

    // compose InputImage
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in android
        format: format, // used only in android
        bytesPerRow: plane.bytesPerRow, // used only in android
      ),
    );
  }

  @override
  void dispose() {
    _scanResetTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear Código de Barras')),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController!),
                // You can add a scanner overlay here if you want
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red,
                      width: 4.0,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Apunte la cámara al código de barras',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
    );
  }
}