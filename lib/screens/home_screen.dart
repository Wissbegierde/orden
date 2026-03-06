import 'package:flutter/material.dart';
import '../widgets/module_card.dart';
import 'income/income_screen.dart';
import 'bills/bills_screen.dart';
import 'shopping/shopping_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Orden',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      Text(
                        'Gestión para tu negocio',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Módulos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    ModuleCard(
                      icon: Icons.trending_up_rounded,
                      label: 'INGRESOS',
                      color: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IncomeScreen()),
                      ),
                    ),
                    ModuleCard(
                      icon: Icons.shopping_bag,
                      label: 'COMPRAS',
                      color: const Color(0xFFF2D51D),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShoppingScreen()),
                      ),
                    ),
                    ModuleCard(
                      icon: Icons.trending_down_rounded,
                      label: 'GASTOS',
                      color: const Color(0xFFEF4444),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BillsScreen()),
                      ),
                    ),
                    ModuleCard(
                      icon: Icons.inventory_2_rounded,
                      label: 'INVENTARIO',
                      color: const Color(0xFF3B82F6),
                      enabled: false,
                    ),
                    ModuleCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'REPORTES',
                      color: const Color(0xFFF59E0B),
                      enabled: false,
                    ),
                    ModuleCard(
                      icon: Icons.settings_rounded,
                      label: 'CONFIGURACIÓN',
                      color: const Color(0xFF6B7280),
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
