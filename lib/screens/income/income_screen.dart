import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/income_payment.dart';
import '../../models/income_sale.dart';
import '../../providers/income_provider.dart';
import 'register_sale_screen.dart';
import 'register_payment_screen.dart';
import 'reports_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM yyyy', 'es').format(today);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ingresos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Ver Reportes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<IncomeSale>>(
                  stream: context.read<IncomeProvider>().salesForDay(today),
                  builder: (ctx, snap) {
                    final sales = snap.data ?? [];
                    final total = sales.fold(0.0, (sum, s) => sum + s.amount);
                    final formatted = NumberFormat.currency(
                      locale: 'es_CO',
                      symbol: '\$',
                      decimalDigits: 0,
                    ).format(total);
                    return Text(
                      formatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const Text(
                  'Total del día',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Registrar\nVenta',
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterSaleScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.handshake_outlined,
                    label: 'Registrar\nAbono',
                    color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterPaymentScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── TabBar ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Ventas de hoy'),
                Tab(text: 'Abonos de hoy'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Página 1: Ventas ─────────────────────────────────
                StreamBuilder<List<IncomeSale>>(
                  stream: context.read<IncomeProvider>().salesForDay(today),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                        ),
                      );
                    }
                    final sales = snap.data ?? [];
                    if (sales.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No hay ventas registradas hoy',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      itemCount: sales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _SaleTile(sale: sales[i]),
                    );
                  },
                ),

                // ── Página 2: Abonos ─────────────────────────────────
                StreamBuilder<List<IncomePayment>>(
                  stream: context.read<IncomeProvider>().paymentsForDay(today),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                      );
                    }
                    final payments = snap.data ?? [];
                    if (payments.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.handshake_outlined,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No hay abonos registrados hoy',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      itemCount: payments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _PaymentTile(payment: payments[i]),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final IncomeSale sale;
  const _SaleTile({required this.sale});

  Color get _typeColor {
    switch (sale.paymentType) {
      case PaymentType.efectivo:
        return const Color(0xFF10B981);
      case PaymentType.credito:
        return const Color(0xFFEF4444);
      case PaymentType.nequi:
        return const Color(0xFF8B5CF6);
      case PaymentType.transferencia:
        return const Color(0xFF06B6D4); // Cyan
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(sale.amount);
    final time = DateFormat('hh:mm a').format(sale.date);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.attach_money_rounded,
              color: _typeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.clientName?.isNotEmpty == true
                      ? sale.clientName!
                      : 'Cliente general',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  sale.paymentType.label,
                  style: TextStyle(
                    color: _typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatted,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final IncomePayment payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(payment.amount);
    final time = DateFormat('hh:mm a').format(payment.date);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.handshake_outlined,
              color: Color(0xFF3B82F6),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.clientName.isNotEmpty
                      ? payment.clientName
                      : 'Cliente general',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(
                    payment.notes!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatted,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF3B82F6),
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
