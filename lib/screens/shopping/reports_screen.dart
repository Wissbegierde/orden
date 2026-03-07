import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/shopping.dart';
import '../../providers/shopping_provider.dart';

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

  List<Shopping> _purchases = [];
  List<ShoppingPayment> _payments = [];
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
    final provider = context.read<ShoppingProvider>();
    final purchases = await provider.fetchShoppingsForRange(from, to);
    final payments = await provider.fetchPaymentsForRange(from, to);
    setState(() {
      _purchases = purchases;
      _payments = payments;
      _loading = false;
    });
  }

  (List<Map<PaymentType, double>>, List<String>) _buildChartData() {
    final now = DateTime.now();

    if (_period == ReportPeriod.daily) {
      final data = List.generate(
        24,
        (_) => {
          PaymentType.efectivo: 0.0,
          PaymentType.credito: 0.0,
          PaymentType.transferencia: 0.0,
          PaymentType.tarjeta: 0.0,
        },
      );
      final labels = List.generate(24, (i) => i % 6 == 0 ? '$i:00' : '');
      for (final b in _purchases) {
        data[b.date.hour][b.paymentType] =
            (data[b.date.hour][b.paymentType] ?? 0) + b.amount;
      }
      return (data, labels);
    } else if (_period == ReportPeriod.weekly) {
      final data = List.generate(
        7,
        (_) => {
          PaymentType.efectivo: 0.0,
          PaymentType.credito: 0.0,
          PaymentType.transferencia: 0.0,
          PaymentType.tarjeta: 0.0,
        },
      );
      final labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      for (final b in _purchases) {
        final dayIndex = b.date.weekday - 1;
        data[dayIndex][b.paymentType] =
            (data[dayIndex][b.paymentType] ?? 0) + b.amount;
      }
      return (data, labels);
    } else {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final numWeeks = (daysInMonth / 7).ceil();
      final data = List.generate(
        numWeeks,
        (_) => {
          PaymentType.efectivo: 0.0,
          PaymentType.credito: 0.0,
          PaymentType.transferencia: 0.0,
          PaymentType.tarjeta: 0.0,
        },
      );
      final labels = List.generate(numWeeks, (i) => 'Sem ${i + 1}');
      for (final b in _purchases) {
        final weekIndex = ((b.date.day - 1) / 7).floor();
        data[weekIndex][b.paymentType] =
            (data[weekIndex][b.paymentType] ?? 0) + b.amount;
      }
      return (data, labels);
    }
  }

  Color _getColor(PaymentType type) {
    switch (type) {
      case PaymentType.efectivo:
        return const Color(0xFF10B981);
      case PaymentType.credito:
        return const Color(0xFFEF4444);
      case PaymentType.transferencia:
        return const Color(0xFF3B82F6);
      case PaymentType.tarjeta:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPurchases = _purchases.fold(0.0, (s, e) => s + e.amount);
    final totalPayments = _payments.fold(0.0, (s, e) => s + e.amount);
    final pendingTotal = _purchases
        .where((b) => !b.paid)
        .fold(0.0, (s, e) => s + e.amount);

    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final chartTuple = _buildChartData();
    final chartData = chartTuple.$1;
    final chartLabels = chartTuple.$2;

    double maxY = 0;
    for (var group in chartData) {
      double sum = group.values.fold(0, (a, b) => a + b);
      if (sum > maxY) maxY = sum;
    }
    if (maxY == 0) maxY = 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2D51D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Reportes de Compras'),
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
              child: CircularProgressIndicator(color: Color(0xFFF2D51D)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjetas de resumen
                    Row(
                      children: [
                        _SummaryCard(
                          label: 'Total Compras',
                          value: currency.format(totalPurchases),
                          icon: Icons.shopping_cart_outlined,
                          color: const Color(0xFFF2D51D),
                        ),
                        const SizedBox(width: 12),
                        _SummaryCard(
                          label: 'Pagado',
                          value: currency.format(totalPayments),
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Tarjeta de pendiente
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pending_outlined,
                            color: Color(0xFFEF4444),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currency.format(pendingTotal),
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Text(
                                'Pendiente de pago',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Leyenda
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: PaymentType.values
                          .map(
                            (t) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getColor(t),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  t.label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),

                    // Gráfica
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
                            barGroups:
                                chartData.asMap().entries.map((e) {
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

                    // Detalle de compras
                    if (_purchases.isNotEmpty) ...[
                      const Text(
                        'Detalle de compras',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._purchases.map(
                        (b) => Container(
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
                                  color: _getColor(b.paymentType),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.providerName?.isNotEmpty == true
                                          ? b.providerName!
                                          : b.description,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${b.paymentType.label} · ${DateFormat('dd/MM hh:mm a').format(b.date)}',
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
                                    currency.format(b.amount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getColor(b.paymentType),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: b.paid
                                          ? const Color(0xFF10B981)
                                              .withValues(alpha: 0.15)
                                          : const Color(0xFFEF4444)
                                              .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      b.paid ? 'Pagado' : 'Pendiente',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: b.paid
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Detalle de pagos a proveedores
                    if (_payments.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Pagos a proveedores',
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
                              const Icon(
                                Icons.handshake_outlined,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.notes ?? 'Pago a proveedor',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd/MM hh:mm a').format(p.date),
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
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (_purchases.isEmpty && _payments.isEmpty)
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
                fontSize: 16,
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