import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import 'register_expense_screen.dart';
import 'register_expense_payment_screen.dart';
import 'deleted_edited_expenses_screen.dart';
import 'expense_reports_screen.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM yyyy', 'es').format(today);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Gastos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE11D48),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Ver Eliminados y Editados',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeletedEditedExpensesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Ver Reportes',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseReportsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen del día
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE11D48),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                StreamBuilder<List<Expense>>(
                   stream: context.read<ExpenseProvider>().expensesStream(),
                   builder: (ctx, snap) {
                      final allGastos = snap.data ?? [];
                      // Filtrar los de "hoy" para el resumen usando lógica local segura
                      final todaySales = allGastos.where((e) {
                         return e.date.year == today.year && e.date.month == today.month && e.date.day == today.day;
                      }).toList();
                      
                      final total = todaySales.fold(0.0, (sum, g) => sum + g.amount);
                      final formatted = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(total);
                      
                      return Text(formatted, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold));
                   },
                ),
                const Text('Total gastado hoy', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          // Botones de Acción
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.add_shopping_cart,
                    label: 'Registrar\nGasto',
                    color: const Color(0xFFE11D48),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterExpenseScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.payment,
                    label: 'Pagar\nCrédito',
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterExpensePaymentScreen())),
                  ),
                ),
              ],
            ),
          ),
          // Lista de Gastos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                 Text('Gastos del Día / Recientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1B4B))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Expense>>(
               stream: context.read<ExpenseProvider>().expensesStream(),
               builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                     return const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)));
                  }
                  final allGastos = snap.data ?? [];
                  
                  if (allGastos.isEmpty) {
                     return const Center(
                        child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                              Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No hay gastos registrados', style: TextStyle(color: Colors.grey)),
                           ],
                        ),
                     );
                  }

                  return ListView.separated(
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                     itemCount: allGastos.length,
                     separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                     itemBuilder: (ctx, i) => _ExpenseTile(expense: allGastos[i]),
                  );
               },
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

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  Color get _typeColor {
    switch (expense.paymentType) {
      case ExpensePaymentType.credito: return const Color(0xFFF59E0B); // Naranja
      default: return const Color(0xFFE11D48); // Rojo general
    }
  }

  void _confirmDelete(BuildContext context) {
    if (expense.paidAmount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puede eliminar un gasto que ya tiene abonos')),
      );
      return;
    }

    final reasonCtrl = TextEditingController();
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Flexible(child: Text('Eliminar Gasto', style: TextStyle(fontSize: 18))),
          ],
        ),
        // Usar SingleChildScrollView + constraints para evitar BOTTOM OVERFLOW
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.4,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Está a punto de eliminar:',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  expense.name?.isNotEmpty == true ? expense.name! : expense.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  currency.format(expense.amount),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Escriba el motivo de eliminación:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Motivo (requerido)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLength: 100,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Debe ingresar un motivo')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await context.read<ExpenseProvider>().deleteExpense(expense, reasonCtrl.text.trim());
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatted = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(expense.amount);
    final time = DateFormat('hh:mm a - dd/MM/yyyy').format(expense.date);
    final isCredit = expense.paymentType == ExpensePaymentType.credito;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Para que el icono no baje si hay mucho texto
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isCredit ? Icons.credit_score : Icons.money_off, color: _typeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (expense.name != null && expense.name!.isNotEmpty)
                  Text(expense.name!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                Text(expense.categoryName, style: TextStyle(fontWeight: expense.name?.isNotEmpty == true ? FontWeight.normal : FontWeight.w600, fontSize: 13, color: Colors.blueGrey)),
                if (expense.providerName != null)
                   Text('Proveedor: ${expense.providerName}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey), overflow: TextOverflow.ellipsis),
                Text(expense.paymentType.label, style: TextStyle(color: _typeColor, fontSize: 12, fontWeight: FontWeight.w500)),
                if (isCredit) ...[
                   Text('Pagado: \$${NumberFormat.compact().format(expense.paidAmount)}', style: const TextStyle(fontSize: 11, color: Colors.green)),
                   Text('Pendiente: \$${NumberFormat.compact().format(expense.pendingAmount)}', style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
                if (expense.notes?.isNotEmpty == true)
                   Padding(
                     padding: const EdgeInsets.only(top: 4),
                     child: Text(expense.notes!, style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                   ),
              ],
            ),
          ),
          Column(
             mainAxisAlignment: MainAxisAlignment.start,
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
                Text(formatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E1B4B))),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                   children: [
                      IconButton(
                         icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                         constraints: const BoxConstraints(),
                         padding: const EdgeInsets.all(4),
                         onPressed: () {
                            if (expense.paidAmount > 0) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No puede editar un gasto que ya tiene abonos')));
                               return;
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterExpenseScreen(expenseToEdit: expense)));
                         },
                      ),
                      IconButton(
                         icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                         constraints: const BoxConstraints(),
                         padding: const EdgeInsets.all(4),
                         onPressed: () => _confirmDelete(context),
                      ),
                   ],
                )
             ],
          ),
        ],
      ),
    );
  }
}
