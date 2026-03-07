import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Encabezado de sección dentro de formularios de autenticación.
///
/// Reemplaza el helper `_seccion()` que estaba duplicado en ambas
/// pantallas de registro (legacy y nueva).
///
/// Ejemplo de uso:
/// ```dart
/// const SectionLabel('Datos personales'),
/// ```
class SectionLabel extends StatelessWidget {
  final String titulo;

  const SectionLabel(this.titulo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primario,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            color: AppColors.primario,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
