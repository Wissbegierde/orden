import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/income_sale.dart' as inc;
import '../../models/bill.dart' as bills;
import '../../models/shopping.dart' as shop;
import '../../providers/income_provider.dart';
import '../../providers/bills_provider.dart';
import '../../providers/shopping_provider.dart';

enum ReportPeriod { daily, weekly, monthly }

class ReportsModuleScreen extends StatefulWidget {
  const ReportsModuleScreen({super.key});

  @override
  State<ReportsModuleScreen> createState() => _ReportsModuleScreenState();
}

class _ReportsModuleScreenState extends State<ReportsModuleScreen>
    with SingleTickerProviderStateMixin {
  ReportPeriod _period = ReportPeriod.daily;

  List<inc.IncomeSale> _sales = [];
  List<bills.Bill> _bills = [];
  List<bills.BillPayment> _billPayments = [];
  List<shop.Shopping> _shoppings = [];
  List<shop.Shopping> _allShoppings = [];
  Map<String, double> _totalPaidByShoppingId = {};

  bool _loading = false;

  @override
  void initState() {
    super.initState();
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

    final incomeProvider = context.read<IncomeProvider>();
    final billsProvider = context.read<BillsProvider>();
    final shoppingProvider = context.read<ShoppingProvider>();

    final results = await Future.wait([
      incomeProvider.fetchSalesForRange(from, to),
      billsProvider.fetchBillsForRange(from, to),
      billsProvider.fetchPaymentsForRange(from, to),
      shoppingProvider.fetchShoppingsForRange(from, to),
      shoppingProvider.fetchPaymentsForRange(from, to),
      shoppingProvider.fetchTotalPaidByShoppingId(),
      shoppingProvider.fetchAllShoppings(),
    ]);

    setState(() {
      _sales = results[0] as List<inc.IncomeSale>;
      _bills = results[1] as List<bills.Bill>;
      _billPayments = results[2] as List<bills.BillPayment>;
      _shoppings = results[3] as List<shop.Shopping>;
      // results[4] = shopping payments (solo para completar Future.wait)
      _totalPaidByShoppingId = results[5] as Map<String, double>;
      _allShoppings = results[6] as List<shop.Shopping>;
      _loading = false;
    });
  }

  void _changePeriod(ReportPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Reportes Generales'),

          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Flujo de Caja'),
              Tab(text: 'Por Cobrar'),
              Tab(text: 'Por Pagar'),
              Tab(text: 'Estado Resultado'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PeriodChip(
                    label: 'Día',
                    selected: _period == ReportPeriod.daily,
                    onTap: () => _changePeriod(ReportPeriod.daily),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Semana',
                    selected: _period == ReportPeriod.weekly,
                    onTap: () => _changePeriod(ReportPeriod.weekly),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Mes',
                    selected: _period == ReportPeriod.monthly,
                    onTap: () => _changePeriod(ReportPeriod.monthly),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCashFlowTab(currency),
                  _buildAccountsReceivableTab(currency),
                  _buildAccountsPayableTab(currency),
                  _buildIncomeStatementTab(currency),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowTab(NumberFormat currency) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
      );
    }

    final ingresosEfectivo = _sales
        .where((s) => s.paymentType == inc.PaymentType.efectivo)
        .fold<double>(0.0, (sum, s) => sum + s.amount);

    final comprasEfectivo = _shoppings
        .where((c) => c.paymentType == shop.PaymentType.efectivo)
        .fold<double>(0.0, (sum, c) => sum + c.amount);

    final gastosEfectivo = _bills
        .where((g) => g.paymentType == bills.PaymentType.efectivo)
        .fold<double>(0.0, (sum, g) => sum + g.amount);

    final totalCaja = ingresosEfectivo - comprasEfectivo - gastosEfectivo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flujo de Caja',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Muestra el dinero que entra y sale en el período seleccionado solo en efectivo.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _CashFlowRow(
            label: 'Ingresos recibidos en efectivo',
            amount: ingresosEfectivo,
            color: const Color(0xFF10B981),
            currency: currency,
            prefix: '+',
          ),
          const SizedBox(height: 12),
          _CashFlowRow(
            label: 'Compras pagadas en efectivo',
            amount: comprasEfectivo,
            color: const Color(0xFFF97316),
            currency: currency,
            prefix: '-',
          ),
          const SizedBox(height: 12),
          _CashFlowRow(
            label: 'Gastos pagados en efectivo',
            amount: gastosEfectivo,
            color: const Color(0xFFEF4444),
            currency: currency,
            prefix: '-',
          ),
          const Divider(height: 32),
          _CashFlowRow(
            label: 'Total en la Caja',
            amount: totalCaja,
            color: totalCaja >= 0
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
            currency: currency,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsReceivableTab(NumberFormat currency) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
      );
    }

    final creditByClient = <String, double>{};
    for (final sale in _sales) {
      if (sale.paymentType != inc.PaymentType.credito) continue;

      final pending = sale.pendingAmount ?? sale.amount;
      if (pending <= 0) continue;

      final client = (sale.clientName?.trim().isNotEmpty == true)
          ? sale.clientName!.trim()
          : 'Sin cliente';

      creditByClient[client] = (creditByClient[client] ?? 0) + pending;
    }

    final entries = creditByClient.entries
        .map((e) => _BalanceEntry(name: e.key, balance: e.value))
        .toList();

    entries.sort((a, b) => b.balance.compareTo(a.balance));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cuentas por Cobrar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clientes que deben por ventas realizadas a crédito a la fecha del período.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No hay cuentas por cobrar pendientes.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...entries.map(
              (e) => _BalanceTile(
                title: e.name,
                amount: e.balance,
                currency: currency,
                color: const Color(0xFF3B82F6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountsPayableTab(NumberFormat currency) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
      );
    }

    // Compras con saldo pendiente (todas las formas de pago, descuenta pagos)
    final balanceByProviderCompras = <String, double>{};
    final descriptionsByProviderCompras = <String, List<String>>{};
    for (final s in _allShoppings) {
      if (s.id == null) continue;
      final totalPaid = _totalPaidByShoppingId[s.id!] ?? 0;
      final balance = s.amount - totalPaid;
      if (balance <= 0) continue;
      final key =
          (s.providerName?.trim().isNotEmpty == true
                  ? s.providerName!
                  : s.description)
              .trim();
      balanceByProviderCompras[key] =
          (balanceByProviderCompras[key] ?? 0) + balance;
      descriptionsByProviderCompras
          .putIfAbsent(key, () => [])
          .add(s.description);
    }

    final comprasEntries = <_BalanceEntry>[];
    for (final e in balanceByProviderCompras.entries) {
      final descriptions = descriptionsByProviderCompras[e.key];
      final subtitle = (descriptions != null && descriptions.isNotEmpty)
          ? descriptions.join(' · ')
          : null;
      comprasEntries.add(_BalanceEntry(
        name: e.key,
        balance: e.value,
        subtitle: subtitle,
      ));
    }
    comprasEntries.sort((a, b) => b.balance.compareTo(a.balance));

    // Gastos (pendientes según pagos realizados; descripciones por proveedor)
    final creditBillsByProvider = <String, double>{};
    final descriptionsByProviderGastos = <String, List<String>>{};
    for (final b in _bills) {
      final key =
          (b.providerName?.trim().isNotEmpty == true
                  ? b.providerName!
                  : b.description)
              .trim();
      creditBillsByProvider[key] = (creditBillsByProvider[key] ?? 0) + b.amount;
      descriptionsByProviderGastos
          .putIfAbsent(key, () => [])
          .add(b.description);
    }

    final billById = <String, bills.Bill>{};
    for (final b in _bills) {
      if (b.id != null) billById[b.id!] = b;
    }
    final paymentsBillsByProvider = <String, double>{};
    for (final p in _billPayments) {
      final b = billById[p.billId];
      if (b == null) continue;
      final key =
          (b.providerName?.trim().isNotEmpty == true
                  ? b.providerName!
                  : b.description)
              .trim();
      paymentsBillsByProvider[key] =
          (paymentsBillsByProvider[key] ?? 0) + p.amount;
    }

    final gastosEntries = <_BalanceEntry>[];
    final providersGastos = {
      ...creditBillsByProvider.keys,
      ...paymentsBillsByProvider.keys,
    };
    for (final p in providersGastos) {
      final credit = creditBillsByProvider[p] ?? 0;
      final paid = paymentsBillsByProvider[p] ?? 0;
      final balance = credit - paid;
      if (balance > 0) {
        final descriptions = descriptionsByProviderGastos[p];
        final subtitle = (descriptions != null && descriptions.isNotEmpty)
            ? descriptions.join(' · ')
            : null;
        gastosEntries.add(_BalanceEntry(
          name: p,
          balance: balance,
          subtitle: subtitle,
        ));
      }
    }
    gastosEntries.sort((a, b) => b.balance.compareTo(a.balance));

    final hasData = comprasEntries.isNotEmpty || gastosEntries.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cuentas por Pagar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Deudas con proveedores por compras y gastos a crédito a la fecha del período.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (!hasData)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No hay cuentas por pagar pendientes.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
            if (comprasEntries.isNotEmpty) ...[
              const Text(
                'Compras',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 8),
              ...comprasEntries.map(
                (e) => _BalanceTile(
                  title: e.name,
                  amount: e.balance,
                  currency: currency,
                  color: const Color(0xFFF97316),
                  subtitle: e.subtitle,
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (gastosEntries.isNotEmpty) ...[
              const Text(
                'Gastos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 8),
              ...gastosEntries.map(
                (e) => _BalanceTile(
                  title: e.name,
                  amount: e.balance,
                  currency: currency,
                  color: const Color(0xFFEF4444),
                  subtitle: e.subtitle,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildIncomeStatementTab(NumberFormat currency) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
      );
    }

    final totalIngresos = _sales.fold<double>(0.0, (sum, s) => sum + s.amount);
    final totalCosto = _shoppings.fold<double>(0.0, (sum, c) => sum + c.amount);
    final totalGastos = _bills.fold<double>(0.0, (sum, g) => sum + g.amount);
    final utilidad = totalIngresos - totalCosto - totalGastos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado de Resultado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Muestra si el negocio tuvo utilidad o pérdida en el período seleccionado.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _IncomeRow(
            label: 'Total Ingresos (contado y crédito)',
            amount: totalIngresos,
            currency: currency,
            color: const Color(0xFF10B981),
            prefix: '+',
          ),
          const SizedBox(height: 12),
          _IncomeRow(
            label: 'Total Costo (compras del período)',
            amount: totalCosto,
            currency: currency,
            color: const Color(0xFFF97316),
            prefix: '-',
          ),
          const SizedBox(height: 12),
          _IncomeRow(
            label: 'Total Gastos (contado y crédito)',
            amount: totalGastos,
            currency: currency,
            color: const Color(0xFFEF4444),
            prefix: '-',
          ),
          const Divider(height: 32),
          _IncomeRow(
            label: 'Utilidad / Pérdida',
            amount: utilidad,
            currency: currency,
            color: utilidad >= 0
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFF59E0B),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF1E1B4B),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? const Color(0xFFF59E0B) : Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _CashFlowRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final NumberFormat currency;
  final String? prefix;
  final bool isBold;

  const _CashFlowRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
    this.prefix,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      fontSize: isBold ? 16 : 14,
      color: color,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E1B4B)),
          ),
        ),
        const SizedBox(width: 12),
        Text('${prefix ?? ''} ${currency.format(amount)}', style: textStyle),
      ],
    );
  }
}

class _IncomeRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final NumberFormat currency;
  final String? prefix;
  final bool isBold;

  const _IncomeRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
    this.prefix,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: isBold ? 18 : 14,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E1B4B)),
          ),
        ),
        const SizedBox(width: 12),
        Text('${prefix ?? ''} ${currency.format(amount)}', style: style),
      ],
    );
  }
}

class _BalanceEntry {
  final String name;
  final double balance;
  final String? subtitle;

  _BalanceEntry({
    required this.name,
    required this.balance,
    this.subtitle,
  });
}

class _BalanceTile extends StatelessWidget {
  final String title;
  final double amount;
  final NumberFormat currency;
  final Color color;
  final String? subtitle;

  const _BalanceTile({
    required this.title,
    required this.amount,
    required this.currency,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currency.format(amount),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
