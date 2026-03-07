import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';

class DeletedEditedExpensesScreen extends StatelessWidget {
  const DeletedEditedExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Historial (Eliminados/Editados)'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Expense>>(
        stream: context.read<ExpenseProvider>().deletedOrEditedExpensesStream(),
        builder: (ctx, snap) {
           if (snap.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
           }
           final history = snap.data ?? [];

           if (history.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: const [
                    Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay registros modificados o eliminados', style: TextStyle(color: Colors.grey, fontSize: 16)),
                 ],
               ),
             );
           }

           return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (ctx, i) {
                final e = history[i];
                final isDeleted = e.isDeleted; // Si fue eliminado y editado prevalece eliminado
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                       backgroundColor: isDeleted ? Colors.red.shade100 : Colors.orange.shade100,
                       child: Icon(
                         isDeleted ? Icons.delete_forever : Icons.edit_note,
                         color: isDeleted ? Colors.red : Colors.orange,
                       ),
                    ),
                    title: Text('${e.categoryName} - ${currency.format(e.amount)}', style: TextStyle(
                      decoration: isDeleted ? TextDecoration.lineThrough : null,
                      fontWeight: FontWeight.bold,
                    )),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('dd/MM/yyyy hh:mm a').format(e.date)),
                        if (isDeleted && e.deleteReason != null)
                           Text('Eliminado por: ${e.deleteReason}', style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                        if (!isDeleted && e.isEdited && e.originalAmount != null)
                           Text('Monto original: ${currency.format(e.originalAmount)}', style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                );
              },
           );
        },
      ),
    );
  }
}
