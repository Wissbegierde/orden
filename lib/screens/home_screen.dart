import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/module_card.dart';
import 'income/income_screen.dart';
import 'bills/bills_screen.dart';
import 'shopping/shopping_screen.dart';
import 'reports/global_reports_screen.dart';
import 'inventory/inventory_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SvgPicture.asset(
                              'assets/logo.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'A LA ORDEN',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'JEFE',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: Color(0xFFFACC15),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Su negocio, mi trabajo',
                              style: TextStyle(
                                color: Color(0xFFE0E7FF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: [
                    ModuleCard(
                      icon: Icons.attach_money_rounded,
                      label: 'INGRESOS',
                      color: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IncomeScreen()),
                      ),
                    ),
                    ModuleCard(
                      icon: Icons.shopping_bag_outlined,
                      label: 'COMPRAS',
                      color: const Color(0xFFF2D51D),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShoppingScreen()),
                      ),
                    ),
                    ModuleCard(
                      icon: Icons.receipt_long_rounded,
                      label: 'GASTOS',
                      color: const Color(0xFFEF4444),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BillsScreen()),
                      ),
                    ),
                    ModuleCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'INVENTARIO',
                      color: const Color(0xFF3B82F6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InventoryScreen(),
                        ),
                      ),
                    ),
                    ModuleCard(
                      icon: Icons.stacked_bar_chart_rounded,
                      label: 'REPORTES',
                      color: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportsModuleScreen(),
                        ),
                      ),
                    ),
                    ModuleCard(
                      icon: Icons.settings_suggest_rounded,
                      label: 'CONFIGURACIÓN',
                      color: const Color(0xFF6B7280),
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
