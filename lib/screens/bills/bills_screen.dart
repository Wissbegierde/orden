import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/bill.dart';
import '../../providers/bills_provider.dart';
import '../../services/voice_command_service.dart';
import '../../widgets/voice_overlay.dart';
import 'register_bill_screen.dart';
import 'register_payment_screen.dart';
import 'reports_screen.dart';
import 'deleted_bills_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  bool _handleVoiceCommand(String normalized) {
    if (VoiceCommandService.matchesAny(normalized, VoiceCommandService.registrarGastoAliases)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterBillScreen()));
      return true;
    } else if (VoiceCommandService.matchesAny(normalized, VoiceCommandService.pagoProveedorAliases)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterBillPaymentScreen()));
      return true;
    } else if (VoiceCommandService.matchesAny(normalized, VoiceCommandService.reportesModuloAliases)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsReportsScreen()));
      return true;
    } else if (VoiceCommandService.matchesAny(normalized, VoiceCommandService.volverAliases)) {
      Navigator.pop(context);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM yyyy', 'es').format(today);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Gastos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // 🔴 BOTÓN TEMPORAL PARA LIMPIAR TODO
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'LIMPIAR TODO',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('⚠️ ADVERTENCIA'),
                  content: const Text(
                    '¿Estás COMPLETAMENTE SEGURO?\n\n'
                    'Esto eliminará:\n'
                    '• Todos los gastos\n'
                    '• Todos los pagos\n'
                    '• Todo el historial\n\n'
                    'ESTA ACCIÓN NO SE PUEDE DESHACER',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);

                        // Mostrar loading
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          await context.read<BillsProvider>().deleteAllData();

                          if (context.mounted) {
                            Navigator.pop(context); // Cerrar loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Base de datos limpiada'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Cerrar loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'SÍ, ELIMINAR TODO',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // FIN DEL BOTÓN TEMPORAL
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Gastos Eliminados',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeletedBillsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Ver Reportes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BillsReportsScreen()),
            ),
          ),
        ],
      ),
      body: VoiceCommandOverlay(
        accentColor: const Color(0xFFEF4444),
        onCommand: _handleVoiceCommand,
        child: Column(
        children: [
          // Summary header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
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
                StreamBuilder<List<Bill>>(
                  stream: context.read<BillsProvider>().billsForDay(today),
                  builder: (ctx, snap) {
                    final bills = snap.data ?? [];
                    final total = bills.fold(0.0, (sum, b) => sum + b.amount);
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
                  'Total gastos del día',
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
                    label: 'Registrar\nGasto',
                    color: const Color(0xFFEF4444),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterBillScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterBillPaymentScreen(),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.credit_card_rounded,
                            color: Color(0xFFF59E0B),
                            size: 28,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pagar\nCrédito',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List of bills
          Expanded(
            child: StreamBuilder<List<Bill>>(
              stream: context.read<BillsProvider>().billsStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bills = snap.data ?? [];
                if (bills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin gastos registrados',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: bills.length,
                  itemBuilder: (ctx, i) => _BillCard(bill: bills[i]),
                );
              },
            ),
          ),
        ],
      ),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final formatted = currencyFmt.format(bill.amount);
    final timeStr = DateFormat('hh:mm a – dd/MM/yyyy', 'es').format(bill.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: _getCategoryColor(),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bill.categoryLabel,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      if (bill.providerName != null &&
                          bill.providerName!.isNotEmpty)
                        Text(
                          'Proveedor: ${bill.providerName}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Amount + edit/delete
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatted,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 18,
                            color: Colors.grey,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterBillScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_rounded,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showDeleteDialog(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Payment type badge + paid/pending
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getPaymentTypeColor(
                      bill.paymentType,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bill.paymentType.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getPaymentTypeColor(bill.paymentType),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: bill.paid
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bill.paid ? 'Pagado' : 'Pendiente',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: bill.paid
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
            // Notes
            if (bill.notes != null && bill.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                bill.notes!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Estás seguro de que deseas eliminar este gasto?\n\nEsta acción no se puede deshacer.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo de eliminación *',
                border: OutlineInputBorder(),
                hintText: 'Ej: Gasto duplicado, error de registro...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes ingresar un motivo de eliminación'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await context.read<BillsProvider>().softDeleteBill(
                  bill.id!,
                  reasonController.text.trim(),
                  'Usuario', // TODO: Obtener el usuario actual
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gasto eliminado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    if (bill.customCategory != null) {
      return const Color(0xFF6B7280);
    }
    switch (bill.category) {
      case BillCategory.arriendo:
        return const Color(0xFF3B82F6);
      case BillCategory.servicios:
        return const Color(0xFF8B5CF6);
      case BillCategory.salarios:
        return const Color(0xFF10B981);
      case BillCategory.utiles:
        return const Color(0xFFF59E0B);
      case BillCategory.otros:
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getCategoryIcon() {
    if (bill.customCategory != null) {
      return Icons.more_horiz_rounded;
    }
    switch (bill.category) {
      case BillCategory.arriendo:
        return Icons.home_rounded;
      case BillCategory.servicios:
        return Icons.electric_bolt_rounded;
      case BillCategory.salarios:
        return Icons.group_rounded;
      case BillCategory.utiles:
        return Icons.cleaning_services_rounded;
      case BillCategory.otros:
        return Icons.more_horiz_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  Color _getPaymentTypeColor(PaymentType type) {
    switch (type) {
      case PaymentType.efectivo:
        return const Color(0xFF10B981);
      case PaymentType.nequi:
        return const Color(0xFF8B5CF6);
      case PaymentType.transferencia:
        return const Color(0xFF3B82F6);
      case PaymentType.tarjeta:
        return const Color(0xFFF59E0B);
    }
  }
}
