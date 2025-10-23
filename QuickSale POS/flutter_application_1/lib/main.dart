import 'package:flutter/material.dart';
import 'package:quicksale_pos/screens/splash_screen.dart';
import 'package:quicksale_pos/theme/app_theme.dart';
import 'package:quicksale_pos/helpers/database_helper.dart'; // Importa el DatabaseHelper

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que Flutter esté inicializado para operaciones async
  await DatabaseHelper()
      .database; // Inicializa la base de datos y crea el usuario admin si no existe
  runApp(const QuickSaleApp());
}

class QuickSaleApp extends StatelessWidget {
  const QuickSaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickSale POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // O .dark para forzar el modo oscuro
      home: const SplashScreen(), // La app ahora empieza aquí
    );
  }
}
