import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/inventory_provider.dart';
import '../../services/voice_command_service.dart';
import '../../widgets/voice_overlay.dart';
import 'register_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _handleVoiceCommand(String normalized) {
    if (VoiceCommandService.matchesAny(normalized, VoiceCommandService.nuevoProductoAliases)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterProductScreen()));
      return true;
    } else if (VoiceCommandService.matchesAny(normalized, VoiceCommandService.volverAliases)) {
      Navigator.pop(context);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6), // Azul para inventario
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Inventario'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_rounded),
        label: const Text('Registrar Producto'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterProductScreen()),
          );
        },
      ),
      body: VoiceCommandOverlay(
        accentColor: const Color(0xFF3B82F6),
        onCommand: _handleVoiceCommand,
        child: StreamBuilder<List<Product>>(
        stream: context.read<InventoryProvider>().stockStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay productos registrados',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final expiringSoon = products
              .where((p) => p.isExpiringSoon || p.isExpired)
              .toList()
            ..sort((a, b) {
              if (a.expiryDate == null) return 1;
              if (b.expiryDate == null) return -1;
              return a.expiryDate!.compareTo(b.expiryDate!);
            });

          return ListView(
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 80,
            ),
            children: [
              if (expiringSoon.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.orange.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: Colors.orange.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Productos próximos a vencer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...expiringSoon.map((p) {
                          final isExpired = p.isExpired;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  isExpired
                                      ? Icons.error_outline
                                      : Icons.warning_amber_rounded,
                                  size: 18,
                                  color: isExpired
                                      ? Colors.red
                                      : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1E1B4B),
                                    ),
                                  ),
                                ),
                                Text(
                                  p.expiryDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(p.expiryDate!)
                                      : '-',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isExpired
                                        ? Colors.red
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
              ...List.generate(products.length, (index) {
                final p = products[index];
                final isLowStock = p.quantity < 5; // Umbral de alerta

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isLowStock
                        ? Border.all(
                            color: Colors.red.withValues(alpha: 0.5),
                            width: 1.5,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isLowStock
                              ? Colors.red.withValues(alpha: 0.1)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isLowStock
                              ? Icons.warning_amber_rounded
                              : Icons.inventory_2_rounded,
                          color: isLowStock
                              ? Colors.red
                              : const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Precio: ${currency.format(p.price)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Stock',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            '${p.quantity}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: isLowStock
                                  ? Colors.red
                                  : const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  size: 20,
                                  color: Colors.blueGrey,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RegisterProductScreen(productToEdit: p),
                                    ),
                                  );
                                },
                                tooltip: 'Editar producto',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_rounded,
                                  size: 20,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _confirmDelete(context, p),
                                tooltip: 'Eliminar producto',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
            }),
            ],
          );
        },
      ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text(
          'Estás a punto de eliminar "${p.name}". Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<InventoryProvider>().deleteProduct(p.id);
    }
  }
}
