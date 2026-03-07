import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

/// Encabezado visual compartido por todas las pantallas de autenticación.
///
/// Actualizado: usa [Color.withValues(alpha:)] en lugar del deprecado [withOpacity()].
class AuthHeader extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final bool grande;

  const AuthHeader({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.grande = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.gradienteHeader,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          28,
          topPadding + (grande ? 24 : 16),
          28,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: screenHeight * (grande ? 0.17 : 0.13),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.store_outlined,
                size: screenHeight * (grande ? 0.10 : 0.08),
                // ✅ withValues en lugar de withOpacity (deprecado en Flutter 3.x)
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                // ✅ withValues en lugar de withOpacity
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
