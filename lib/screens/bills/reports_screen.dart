import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/bill.dart';
import '../../providers/bills_provider.dart';

enum ReportPeriod { daily, weekly, monthly }

class BillsReportsScreen extends StatefulWidget {
  const BillsReportsScreen({super.key});

  @override
  State<BillsReportsScreen> createState() => _BillsReportsScreenState();
}

class _BillsReportsScreenState extends State<BillsReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportPeriod _period = ReportPeriod.daily;

  List<Bill> _bills = [];
  List<BillPayment> _payments = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _period = ReportPeriod.values[_tabController.index]);
        _load();
      }
    });
    _load();
  }

  (DateTime, DateTime) _range() {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.daily:
        final start = DateTime(now.year, now.month, now.day);
        return (start, start.add(const Duration(days: 1)));
      case ReportPeriod.weekly:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final s = DateTime(start.year, start.month, start.day);
        return (s, s.add(const Duration(days: 7)));
      case ReportPeriod.monthly:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return (start, end);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final (from, to) = _range();
    final provider = context.read<BillsProvider>();
    final results = await Future.wait([
      provider.fetchBillsForRange(from, to),
      provider.fetchPaymentsForRange(from, to),
    ]);
    setState(() {
      _bills = results[0] as List<Bill>;
      _payments = results[1] as List<BillPayment>;
      _loading = false;
    });
  }

  (List<Map<String, double>>, List<String>) _buildChartData() {
    final now = DateTime.now();

    if (_period == ReportPeriod.daily) {
      final data = List.generate(24, (_) => <String, double>{});
      final labels = List.generate(24, (i) => i % 6 == 0 ? '$i:00' : '');
      for (final bill in _bills) {
        final categoryKey =
            bill.customCategory ?? bill.category?.name ?? 'otros';
        data[bill.date.hour][categoryKey] =
            (data[bill.date.hour][categoryKey] ?? 0) + bill.amount;
      }
      return (data, labels);
    } else if (_period == ReportPeriod.weekly) {
      final data = List.generate(7, (_) => <String, double>{});
      final labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      for (final bill in _bills) {
        final categoryKey =
            bill.customCategory ?? bill.category?.name ?? 'otros';
        final dayIndex = bill.date.weekday - 1;
        data[dayIndex][categoryKey] =
            (data[dayIndex][categoryKey] ?? 0) + bill.amount;
      }
      return (data, labels);
    } else {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final numWeeks = (daysInMonth / 7).ceil();
      final data = List.generate(numWeeks, (_) => <String, double>{});
      final labels = List.generate(numWeeks, (i) => 'Sem ${i + 1}');

      for (final bill in _bills) {
        final categoryKey =
            bill.customCategory ?? bill.category?.name ?? 'otros';
        final weekIndex = ((bill.date.day - 1) / 7).floor();
        data[weekIndex][categoryKey] =
            (data[weekIndex][categoryKey] ?? 0) + bill.amount;
      }
      return (data, labels);
    }
  }

  Color _getCategoryColor(String? categoryKey) {
    if (categoryKey == null) return const Color(0xFF6B7280);

    switch (categoryKey) {
      case 'arriendo':
        return const Color(0xFF3B82F6);
      case 'servicios':
        return const Color(0xFF8B5CF6);
      case 'salarios':
        return const Color(0xFF10B981);
      case 'utiles':
        return const Color(0xFFF59E0B);
      case 'otros':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getCategoryLabel(String? categoryKey) {
    if (categoryKey == null) return 'Otros';

    try {
      final category = BillCategoryExtension.fromString(categoryKey);
      return category.label;
    } catch (_) {
      return categoryKey;
    }
  }

  String _formatAxisValue(double value) {
    if (value == 0) return '0';
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toInt().toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reportes de Gastos'),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFEF4444),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Diario'),
                Tab(text: 'Semanal'),
                Tab(text: 'Mensual'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportTab(),
                _buildReportTab(),
                _buildReportTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final (chartData, labels) = _buildChartData();

    // ✅ SIMPLIFICADO: Total gastos es la suma de todos los gastos
    final totalGastos = _bills.fold(0.0, (sum, b) => sum + b.amount);

    // ✅ SIMPLIFICADO: Total pagado es la suma de TODOS los pagos registrados
    final totalPagos = _payments.fold(0.0, (sum, p) => sum + p.amount);

    // ✅ Pendiente = Gastos - Pagos
    final pendiente = totalGastos - totalPagos;

    // Aggregate by category
    final byCategory = <String, double>{};
    for (final bill in _bills) {
      final categoryKey = bill.customCategory ?? bill.category?.name ?? 'otros';
      byCategory[categoryKey] = (byCategory[categoryKey] ?? 0) + bill.amount;
    }

    // Ordenar categorías
    final sortedCategories = byCategory.keys.toList()
      ..sort((a, b) {
        final aIsPredefined = BillCategory.values.any((cat) => cat.name == a);
        final bIsPredefined = BillCategory.values.any((cat) => cat.name == b);
        if (aIsPredefined && !bIsPredefined) return -1;
        if (!aIsPredefined && bIsPredefined) return 1;
        return a.compareTo(b);
      });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Gastos',
                    amount: totalGastos,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Pagado',
                    amount: totalPagos,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryCard(
              title: 'Pendiente de Pago',
              amount: pendiente,
              color: const Color(0xFFFCD34D),
            ),
            const SizedBox(height: 24),
            if (chartData.isNotEmpty && byCategory.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gastos por Período',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 320,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 8),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              (chartData.fold(
                                        0.0,
                                        (max, group) =>
                                            group.values.fold(
                                                  0.0,
                                                  (sum, v) => sum + v,
                                                ) >
                                                max
                                            ? group.values.fold(
                                                0.0,
                                                (sum, v) => sum + v,
                                              )
                                            : max,
                                      ) *
                                      1.2)
                                  .toDouble(),
                          barGroups: List.generate(
                            chartData.length,
                            (i) => BarChartGroupData(
                              x: i,
                              barRods: sortedCategories
                                  .map(
                                    (catKey) => BarChartRodData(
                                      toY: chartData[i][catKey] ?? 0,
                                      color: _getCategoryColor(catKey),
                                      width: 12,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) => Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[value.toInt()],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 70,
                                getTitlesWidget: (value, meta) => Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Text(
                                    _formatAxisValue(value),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: const FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                            drawVerticalLine: false,
                            horizontalInterval: null,
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Leyenda de categorías
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: sortedCategories
                          .map(
                            (catKey) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(catKey),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getCategoryLabel(catKey),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            const Text(
              'Desglose por Categoría',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (sortedCategories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay gastos en este período',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: sortedCategories
                      .map(
                        (catKey) => Column(
                          children: [
                            _CategoryBreakdown(
                              categoryLabel: _getCategoryLabel(catKey),
                              amount: byCategory[catKey] ?? 0,
                              color: _getCategoryColor(catKey),
                              total: totalGastos,
                            ),
                            if (catKey != sortedCategories.last)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(amount);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              formatted,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final String categoryLabel;
  final double amount;
  final Color color;
  final double total;

  const _CategoryBreakdown({
    required this.categoryLabel,
    required this.amount,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (amount / total * 100) : 0.0;
    final formatted = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(amount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              Text(
                formatted,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}% del total',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(amount / 1000).toStringAsFixed(1)}K',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
