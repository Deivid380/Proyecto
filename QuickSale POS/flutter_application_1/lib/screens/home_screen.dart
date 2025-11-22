import 'package:flutter/material.dart';
import 'package:quicksale_pos/screens/products_screen.dart';
import 'package:quicksale_pos/screens/reports_screen.dart';
import 'package:quicksale_pos/screens/profile_screen.dart';
import 'package:quicksale_pos/models/user.dart'; // Importamos el modelo de usuario
import 'package:quicksale_pos/screens/sales_screen.dart';
import 'package:quicksale_pos/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final User user; // Ahora HomeScreen requiere un objeto User
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions; // Se inicializará en initState

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const SalesScreen(user: widget.user), // Pasamos el usuario a SalesScreen
      const ProductsScreen(),
      ReportsScreen(user: widget.user), // Pasamos el usuario a ReportsScreen
      ProfileScreen(user: widget.user), // Pasamos el usuario a ProfileScreen
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppTheme.gradientBackground(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // No es necesario especificar colores aquí, los tomará del AppTheme
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: 'Ventas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
