import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/income_payment.dart';
import '../../models/income_sale.dart';
import '../../providers/income_provider.dart';

enum ReportPeriod { daily, weekly, monthly }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReportPeriod _period = ReportPeriod.daily;

  List<IncomeSale> _sales = [];
  List<IncomePayment> _payments = [];
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
    final provider = context.read<IncomeProvider>();
    final results = await Future.wait([
      provider.fetchSalesForRange(from, to),
      provider.fetchPaymentsForRange(from, to),
    ]);
    setState(() {
      _sales = results[0] as List<IncomeSale>;
      _payments = results[1] as List<IncomePayment>;
      _loading = false;
    });
  }

  // Generate chart data: List of Groups. Each Group is a X axis point.
  // The Map inside is {PaymentType: value}
  (List<Map<PaymentType, double>>, List<String>) _buildChartData() {
    final now = DateTime.now();

    if (_period == ReportPeriod.daily) {
      // 24 hours
      final data = List.generate(
        24,
        (_) => {
          PaymentType.efectivo: 0.0,
          PaymentType.nequi: 0.0,
          PaymentType.credito: 0.0,
        },
      );
      final labels = List.generate(
        24,
        (i) => i % 6 == 0 ? '$i:00' : '',
      ); // Show label every 6 hours
      for (final s in _sales) {
        data[s.date.hour][s.paymentType] =
            (data[s.date.hour][s.paymentType] ?? 0) + s.amount;
      }
      return (data, labels);
    } else if (_period == ReportPeriod.weekly) {
      // 7 days (Mon-Sun)
      final data = List.generate(
        7,
        (_) => {
          PaymentType.efectivo: 0.0,
          PaymentType.nequi: 0.0,
          PaymentType.credito: 0.0,
        },
      );
      final labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      for (final s in _sales) {
        // weekday is 1-7 (Mon-Sun)
        final dayIndex = s.date.weekday - 1;
        data[dayIndex][s.paymentType] =
            (data[dayIndex][s.paymentType] ?? 0) + s.amount;
      }
      return (data, labels);
    } else {
      // Monthly: Weeks of the month. Usually 4-5.
      // We will divide the month in 4 blocks roughly.
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final numWeeks = (daysInMonth / 7).ceil();
      final data = List.generate(
        numWeeks,
        (_) => {
          PaymentType.efectivo: 0.0,
          PaymentType.nequi: 0.0,
          PaymentType.credito: 0.0,
        },
      );
      final labels = List.generate(numWeeks, (i) => 'Sem ${i + 1}');

      for (final s in _sales) {
        final weekIndex = ((s.date.day - 1) / 7).floor();
        data[weekIndex][s.paymentType] =
            (data[weekIndex][s.paymentType] ?? 0) + s.amount;
      }
      return (data, labels);
    }
  }

  Color _getColor(PaymentType type) {
    switch (type) {
      case PaymentType.efectivo:
        return const Color(0xFF10B981); // Verde
      case PaymentType.nequi:
        return const Color(0xFF8B5CF6); // Morado
      case PaymentType.credito:
        return const Color(0xFFEF4444); // Rojo
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSales = _sales.fold(0.0, (s, e) => s + e.amount);
    final totalPayments = _payments.fold(0.0, (s, e) => s + e.amount);
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final chartTuple = _buildChartData();
    final chartData = chartTuple.$1;
    final chartLabels = chartTuple.$2;

    // Find MaxY
    double maxY = 0;
    for (var group in chartData) {
      double sum = group.values.fold(0, (a, b) => a + b);
      if (sum > maxY) maxY = sum;
    }
    if (maxY == 0) maxY = 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reportes de Ingresos'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Diario'),
            Tab(text: 'Semanal'),
            Tab(text: 'Mensual'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    Row(
                      children: [
                        _SummaryCard(
                          label: 'Total Ventas',
                          value: currency.format(totalSales),
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          label: 'Total Abonos',
                          value: currency.format(totalPayments),
                          icon: Icons.handshake_outlined,
                          color: const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Leyenda
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: PaymentType.values
                          .map(
                            (t) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    color: _getColor(t),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    t.label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),

                    // Chart Stacked
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 250,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxY * 1.2,
                            barGroups: chartData.asMap().entries.map((e) {
                              final int i = e.key;
                              final Map<PaymentType, double> map = e.value;

                              double currentY = 0;
                              final List<BarChartRodStackItem> stackItems = [];

                              for (var type in PaymentType.values) {
                                final val = map[type] ?? 0.0;
                                if (val > 0) {
                                  stackItems.add(
                                    BarChartRodStackItem(
                                      currentY,
                                      currentY + val,
                                      _getColor(type),
                                    ),
                                  );
                                  currentY += val;
                                }
                              }

                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  if (currentY > 0)
                                    BarChartRodData(
                                      toY: currentY,
                                      width: _period == ReportPeriod.daily
                                          ? 8
                                          : 24,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                      rodStackItems: stackItems,
                                    )
                                  else
                                    BarChartRodData(
                                      toY: 0,
                                      width: _period == ReportPeriod.daily
                                          ? 8
                                          : 24,
                                    ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 45,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const SizedBox();
                                    return Text(
                                      NumberFormat.compactCurrency(
                                        symbol: '\$',
                                        decimalDigits: 0,
                                      ).format(value),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 ||
                                        index >= chartLabels.length) {
                                      return const SizedBox();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        chartLabels[index],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sales list
                    if (_sales.isNotEmpty) ...[
                      const Text(
                        'Detalle de ventas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._sales.map(
                        (s) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _getColor(s.paymentType),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.productName ?? 'Venta manual',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${s.paymentType.label} · ${DateFormat('dd/MM hh:mm a').format(s.date)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currency.format(s.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getColor(s.paymentType),
                                    ),
                                  ),
                                  if (s.quantity != null)
                                    Text(
                                      '${s.quantity} unds',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Payments list
                    if (_payments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Detalle de abonos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._payments.map(
                        (p) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.clientName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd/MM hh:mm a',
                                      ).format(p.date),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currency.format(p.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (_sales.isEmpty && _payments.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.bar_chart_rounded,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Sin datos en este período',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
