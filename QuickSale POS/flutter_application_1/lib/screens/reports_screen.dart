import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/sale.dart';
import './sale_detail_screen.dart';
import '../widgets/empty_state.dart';
import './top_products_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Sale>> _salesFuture;
  final dbHelper = DatabaseHelper();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _refreshSales();
  }

  void _refreshSales() {
    setState(() {
      if (_startDate != null && _endDate != null) {
        // Adjust end date to include the entire day
        final adjustedEndDate = _endDate!.add(const Duration(days: 1));
        _salesFuture = dbHelper.getSalesByDateRange(_startDate!, adjustedEndDate);
      } else {
        _salesFuture = dbHelper.getAllSales();
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      end: _endDate ?? DateTime.now(),
    );

    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initialDateRange,
    );

    if (newDateRange != null) {
      setState(() {
        _startDate = newDateRange.start;
        _endDate = newDateRange.end;
      });
      _refreshSales();
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _refreshSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TopProductsScreen()),
              );
            },
            tooltip: 'Productos más vendidos',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSales,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Chip(
                label: Text(
                  '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}',
                ),
                onDeleted: _clearFilter,
                deleteIcon: const Icon(Icons.close, size: 18),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Sale>>(
              future: _salesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyState(
                    icon: Icons.bar_chart_outlined,
                    message: 'No hay ventas para el filtro seleccionado.',
                  );
                }

                final sales = snapshot.data!;

                return ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return ListTile(
                      title: Text('Venta #${sale.id}'),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(sale.date)),
                      trailing: Text('\${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SaleDetailScreen(sale: sale),
                          ),
                        ).then((_) => _refreshSales());
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}