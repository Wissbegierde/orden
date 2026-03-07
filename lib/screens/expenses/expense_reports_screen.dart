import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';

class ExpenseReportsScreen extends StatefulWidget {
  const ExpenseReportsScreen({super.key});

  @override
  State<ExpenseReportsScreen> createState() => _ExpenseReportsScreenState();
}

class _ExpenseReportsScreenState extends State<ExpenseReportsScreen> {
  int _selectedFilter = 0; // 0: Diario, 1: Semanal, 2: Mensual
  DateTime _currentDate = DateTime.now();

  final _currency =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  DateTimeRange get _currentRange {
    final now = _currentDate;
    if (_selectedFilter == 0) {
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    } else if (_selectedFilter == 1) {
      final weekday = now.weekday;
      final start = now.subtract(Duration(days: weekday - 1));
      return DateTimeRange(
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(start.year, start.month, start.day)
            .add(const Duration(days: 7))
            .subtract(const Duration(microseconds: 1)),
      );
    } else {
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 1)
            .subtract(const Duration(microseconds: 1)),
      );
    }
  }

  void _nextPeriod() {
    setState(() {
      if (_selectedFilter == 0) _currentDate = _currentDate.add(const Duration(days: 1));
      else if (_selectedFilter == 1) _currentDate = _currentDate.add(const Duration(days: 7));
      else _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    });
  }

  void _prevPeriod() {
    setState(() {
      if (_selectedFilter == 0) _currentDate = _currentDate.subtract(const Duration(days: 1));
      else if (_selectedFilter == 1) _currentDate = _currentDate.subtract(const Duration(days: 7));
      else _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    });
  }

  String get _periodLabel {
    final fmt = DateFormat('dd MMM yyyy', 'es');
    final range = _currentRange;
    if (_selectedFilter == 0) return fmt.format(range.start);
    if (_selectedFilter == 1) return '${fmt.format(range.start)} - ${fmt.format(range.end)}';
    return DateFormat('MMMM yyyy', 'es').format(range.start).toUpperCase();
  }

  // Mapa de colores por forma de pago
  Color _paymentColor(ExpensePaymentType type) {
    switch (type) {
      case ExpensePaymentType.efectivo:     return const Color(0xFF10B981); // Verde
      case ExpensePaymentType.credito:      return const Color(0xFFF59E0B); // Naranja
      case ExpensePaymentType.transferencia: return const Color(0xFF3B82F6); // Azul
      case ExpensePaymentType.tarjeta:      return const Color(0xFF8B5CF6); // Violeta
    }
  }

  Widget _buildBarChart(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('Sin datos para graficar', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final Map<String, double> totals = {};
    for (var e in expenses) totals[e.categoryName] = (totals[e.categoryName] ?? 0) + e.amount;

    final categories = totals.keys.toList();
    final maxY = totals.values.isEmpty ? 0.0 : totals.values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.25,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= categories.length) return const Text('');
                var name = categories[idx];
                if (name.length > 6) name = '${name.substring(0, 6)}..';
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(name, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                NumberFormat.compact().format(v),
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        barGroups: categories.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: totals[entry.value] ?? 0,
                color: const Color(0xFFE11D48),
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Sección de desglose por forma de pago
  Widget _buildPaymentTypeSummary(List<Expense> expenses) {
    final Map<ExpensePaymentType, double> byType = {};
    for (var e in expenses) {
      byType[e.paymentType] = (byType[e.paymentType] ?? 0) + e.amount;
    }
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

    if (byType.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desglose por Forma de Pago',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B)),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(
            children: ExpensePaymentType.values
                .where((t) => byType.containsKey(t))
                .map((type) {
                  final amount = byType[type] ?? 0;
                  final pct = total > 0 ? (amount / total) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _paymentColor(type).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_paymentIcon(type), color: _paymentColor(type), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade200,
                                  color: _paymentColor(type),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currency.format(amount),
                              style: TextStyle(fontWeight: FontWeight.bold, color: _paymentColor(type)),
                            ),
                            Text(
                              '${(pct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                })
                .toList(),
          ),
        ),
      ],
    );
  }

  IconData _paymentIcon(ExpensePaymentType type) {
    switch (type) {
      case ExpensePaymentType.efectivo:     return Icons.payments_outlined;
      case ExpensePaymentType.credito:      return Icons.credit_score;
      case ExpensePaymentType.transferencia: return Icons.swap_horiz_rounded;
      case ExpensePaymentType.tarjeta:      return Icons.credit_card;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Reportes de Gastos'),
        backgroundColor: const Color(0xFFE11D48),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Selector de filtro
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(label: const Text('Diario'), selected: _selectedFilter == 0,
                    onSelected: (_) => setState(() { _selectedFilter = 0; _currentDate = DateTime.now(); }),
                    selectedColor: const Color(0xFFE11D48).withOpacity(0.2)),
                ChoiceChip(label: const Text('Semanal'), selected: _selectedFilter == 1,
                    onSelected: (_) => setState(() { _selectedFilter = 1; _currentDate = DateTime.now(); }),
                    selectedColor: const Color(0xFFE11D48).withOpacity(0.2)),
                ChoiceChip(label: const Text('Mensual'), selected: _selectedFilter == 2,
                    onSelected: (_) => setState(() { _selectedFilter = 2; _currentDate = DateTime.now(); }),
                    selectedColor: const Color(0xFFE11D48).withOpacity(0.2)),
              ],
            ),
          ),
          // Navegador de fechas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevPeriod),
                Flexible(
                  child: Text(
                    _periodLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextPeriod),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Expense>>(
              future: context
                  .read<ExpenseProvider>()
                  .fetchExpensesForRange(_currentRange.start, _currentRange.end),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)));
                }

                final expenses = snap.data ?? [];
                final total = expenses.fold(0.0, (s, e) => s + e.amount);
                final paid = expenses.fold(0.0, (s, e) => s + e.paidAmount);
                final pending = expenses.fold(0.0, (s, e) => s + e.pendingAmount);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Tarjetas de resumen ───────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Total Gastos',
                              amount: total,
                              color: const Color(0xFFE11D48),
                              icon: Icons.trending_down_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _SummaryCard(
                                  title: 'Pagado',
                                  amount: paid,
                                  color: Colors.green,
                                  icon: Icons.check_circle_outline,
                                  small: true,
                                ),
                                const SizedBox(height: 8),
                                _SummaryCard(
                                  title: 'Deuda pendiente',
                                  amount: pending,
                                  color: const Color(0xFFF59E0B),
                                  icon: Icons.hourglass_bottom,
                                  small: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Gráfica por categoría ─────────────────────────
                      const Text(
                        'Gastos por Categoría',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 230,
                        padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                        ),
                        child: _buildBarChart(expenses),
                      ),
                      const SizedBox(height: 28),

                      // ── Desglose por forma de pago ────────────────────
                      _buildPaymentTypeSummary(expenses),
                      const SizedBox(height: 28),

                      // ── Detalle de gastos ─────────────────────────────
                      const Text(
                        'Detalle de Gastos',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B)),
                      ),
                      const SizedBox(height: 10),

                      if (expenses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              children: [
                                const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text('No hay registros en este periodo',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),

                      ...expenses.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: _paymentColor(e.paymentType).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(_paymentIcon(e.paymentType), color: _paymentColor(e.paymentType), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.name?.isNotEmpty == true ? e.name! : e.categoryName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${e.categoryName} · ${DateFormat('dd MMM').format(e.date)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    e.paymentType.label,
                                    style: TextStyle(fontSize: 11, color: _paymentColor(e.paymentType), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _currency.format(e.amount),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E1B4B)),
                            ),
                          ],
                        ),
                      )).toList(),

                      const SizedBox(height: 20),
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
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final bool small;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(small ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      // Cambio: Column en vez de Row para que el monto tenga ancho completo
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: small ? 16 : 22),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: small ? 11 : 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // FittedBox hace que el texto se encoja si no cabe, nunca overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: small ? 15 : 22,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
