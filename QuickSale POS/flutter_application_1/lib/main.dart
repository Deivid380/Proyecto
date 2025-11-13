import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importa para la localización de fechas
import 'package:intl/intl.dart'; // Importa para la configuración de locale
import 'package:quicksale_pos/screens/splash_screen.dart';
import 'package:quicksale_pos/theme/app_theme.dart';
import 'package:quicksale_pos/helpers/database_helper.dart'; // Importa el DatabaseHelper

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegura que Flutter esté inicializado para operaciones async
  await initializeDateFormatting(
    'es_ES',
    null,
  ); // Inicializa la localización para español
  Intl.defaultLocale = 'es_ES'; // Establece el locale por defecto
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
