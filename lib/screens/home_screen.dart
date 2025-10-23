import 'package:flutter/material.dart';
import 'package:quicksale_pos/screens/products_screen.dart';
import 'package:quicksale_pos/screens/reports_screen.dart';
import 'package:quicksale_pos/screens/profile_screen.dart';
import 'package:quicksale_pos/models/user.dart'; // Importamos el modelo de usuario
import 'package:quicksale_pos/screens/sales_screen.dart';

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
      const SalesScreen(),
      const ProductsScreen(),
      const ReportsScreen(),
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
      body: _widgetOptions.elementAt(
        _selectedIndex,
      ), // Ya no necesitamos Center aquí
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType
            .fixed, // Asegura que todos los items sean visibles
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Ventas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
