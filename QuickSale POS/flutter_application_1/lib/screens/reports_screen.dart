import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:quicksale_pos/models/user.dart';
import 'package:quicksale_pos/screens/user_management_screen.dart';
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
  final dbHelper = DatabaseHelper();

  // Para el filtro de admin
  List<User> _usersForFilter = [];
  int? _selectedUserId;

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
      return; // Esperar a que se seleccione un usuario
    }

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
            child: (_summaryFuture == null || _dailySalesFuture == null)
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder(
                    future: Future.wait([_summaryFuture!, _dailySalesFuture!]),
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
                      final dailySales =
                          snapshot.data![1] as List<Map<String, dynamic>>;

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

  Widget _buildUserFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<int>(
        value: _selectedUserId,
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
    final users = await fetchUsersForReports(dbHelper);
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
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY:
                      dailySales
                          .map((d) => d['total'] as double)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date =
                              dailySales[value.toInt()]['date'] as DateTime;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(DateFormat.E('es_ES').format(date)),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: dailySales.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['total'] as double,
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
