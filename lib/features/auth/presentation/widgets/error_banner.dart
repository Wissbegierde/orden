import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Banner de error animado que se muestra en la parte superior de los formularios.
///
/// Soporta un botón de cierre opcional que invoca [onDismiss].
/// La animación de entrada evita el "pop-in" brusco al aparecer.
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          border: Border.all(color: AppColors.error.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.error_outline, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: AppColors.error, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
