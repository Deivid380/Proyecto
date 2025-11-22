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

class QuickSaleApp extends StatefulWidget {
  const QuickSaleApp({super.key});

  @override
  State<QuickSaleApp> createState() => _QuickSaleAppState();
}

class _QuickSaleAppState extends State<QuickSaleApp> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
      _timer = Timer(const Duration(minutes: 4), _resetApp);
    } else if (state == AppLifecycleState.resumed) {
      _timer?.cancel();
      if (_backgroundTime != null && DateTime.now().difference(_backgroundTime!).inMinutes >= 4) {
        _resetApp();
      }
      _backgroundTime = null; // Clear background time after resuming
    }
  }

  void _resetApp() {
    _timer?.cancel();
    _backgroundTime = null;
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SplashScreen()), // Navigate to your desired reset screen
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickSale POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme
          .lightTheme, // Asegúrate de que AppTheme.lightTheme incorpore los cambios sugeridos
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // O .dark para forzar el modo oscuro
      home: const SplashScreen(), // La app ahora empieza aquí
    );
  }
}
