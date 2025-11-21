import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:quicksale_pos/models/sale.dart';
import 'package:quicksale_pos/models/user.dart';
import 'package:quicksale_pos/screens/sale_detail_screen.dart';
import '../helpers/database_helper.dart';
import '../helpers/currency_formatter.dart';
import '../widgets/empty_state.dart';

class ReportsScreen extends StatefulWidget {
  final User user;
  const ReportsScreen({super.key, required this.user});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Future<Map<String, dynamic>>? _summaryFuture;
  Future<List<Map<String, dynamic>>>? _dailySalesFuture;
  Future<List<Sale>>? _allSalesFuture;
  final dbHelper = DatabaseHelper();

  // Para el filtro de admin
  List<User> _usersForFilter = [];
  int? _selectedUserId;

  Map<int, String> _userNames = {}; // Added to store user IDs and names

  @override
  void initState() {
    super.initState();
    if (widget.user.role == 'admin') {
      _loadUsersForFilter();
      _selectedUserId = 0; // "Todos los usuarios" por defecto
    } else {
      _selectedUserId = widget.user.id;
    }
    _loadReportData();
  }

  void _loadReportData() async {
    if (_selectedUserId == null) {
      return;
    }

    // Load all users to get their names for display
    final allUsers = await dbHelper.getAllUsers();
    setState(() {
      _userNames = { for (var user in allUsers) user.id!: user.username };
    });

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    setState(() {
      _summaryFuture = dbHelper.getSalesSummary(
        startOfToday,
        today,
        userId: _selectedUserId,
      );
      _dailySalesFuture = dbHelper.getDailySalesForLastWeek(
        userId: _selectedUserId,
      );
      _allSalesFuture = dbHelper.getAllSales(userId: _selectedUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.user.role == 'admin') _buildUserFilter(),
          Expanded(
            child: (_summaryFuture == null || _dailySalesFuture == null || _allSalesFuture == null)
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder(
                    future: Future.wait([_summaryFuture!, _dailySalesFuture!, _allSalesFuture!]),
                    builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData) {
                        return const EmptyState(
                          icon: Icons.bar_chart_outlined,
                          message: 'No hay datos para mostrar.',
                        );
                      }

                      final summary = snapshot.data![0] as Map<String, dynamic>;
                      final dailySales = snapshot.data![1] as List<Map<String, dynamic>>;
                      final allSales = snapshot.data![2] as List<Sale>;

                      final totalSales = summary['totalSales'] ?? 0.0;
                      final topProduct = summary['topProduct'];

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSummaryCard(
                              title: 'Ventas Totales de Hoy',
                              content: CurrencyFormatter.format(totalSales),
                              icon: Icons.monetization_on,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            _buildTopProductCard(topProduct),
                            const SizedBox(height: 16),
                            _buildWeeklyChart(dailySales),
                            const SizedBox(height: 24),
                            _buildSalesHistory(allSales),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesHistory(List<Sale> sales) {
    final List<Sale> sortedSales = List<Sale>.from(sales);
    sortedSales.sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial de Ventas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (sortedSales.isEmpty)
          const EmptyState(icon: Icons.history_toggle_off, message: 'No hay ventas registradas.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedSales.length,
            itemBuilder: (context, index) {
              final sale = sortedSales[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text((index + 1).toString()),
                  ),
                  title: Text('Venta #${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sale.date.toString()),
                      Text('Vendedor: ${_userNames[sale.userId] ?? 'Desconocido'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.format(sale.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (widget.user.role == 'admin')
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSale(sale.id!),
                          tooltip: 'Eliminar Venta',
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SaleDetailScreen(sale: sale),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
  Future<void> _deleteSale(int saleId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta venta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await dbHelper.deleteSale(saleId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta eliminada correctamente.')),
      );
      _loadReportData(); // Reload data after deletion
    }
  }

  Widget _buildUserFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<int>(
        initialValue: _selectedUserId,
        decoration: const InputDecoration(
          labelText: 'Ver reportes de',
          border: OutlineInputBorder(),
        ),
        items: _usersForFilter.map((User user) {
          return DropdownMenuItem<int>(
            value: user.id,
            child: Text(user.username),
          );
        }).toList(),
        onChanged: (int? newValue) {
          setState(() {
            _selectedUserId = newValue;
            _loadReportData();
          });
        },
      ),
    );
  }

  Future<void> _loadUsersForFilter() async {
    final users = await dbHelper.getAllUsers();
    users.insert(
      0,
      User(id: 0, username: 'Todos los usuarios', password: '', role: ''),
    );
    setState(() {
      _usersForFilter = users;
    });
  }

  Widget _buildSummaryCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  content,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductCard(Map<String, dynamic>? topProduct) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Producto Más Vendido de Hoy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (topProduct != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topProduct['name'],
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${topProduct['total_quantity']} unidades',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              )
            else
              const Text('No hay datos de productos vendidos hoy.'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> dailySales) {
    if (dailySales.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text("No hay datos de ventas para la última semana."),
        ),
      );
    }

    final double maxSales = dailySales
        .map((d) => d['total'] as double)
        .reduce((a, b) => a > b ? a : b);
    final double chartMaxY = maxSales * 1.2;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ventas de los Últimos 7 Días',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(CurrencyFormatter.format(value),
                              style: const TextStyle(fontSize: 10));
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 || value.toInt() >= dailySales.length) {
                            return const Text('');
                          }
                          final date = dailySales[value.toInt()]['date'] as DateTime;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(DateFormat('dd/MM').format(date),
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (dailySales.length - 1).toDouble(),
                  minY: 0,
                  maxY: chartMaxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailySales.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return FlSpot(index.toDouble(), data['total'] as double);
                      }).toList(),
                      isCurved: true,
                      barWidth: 4,
                      color: Theme.of(context).colorScheme.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                  ],
                  lineTouchData: const LineTouchData(enabled: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
