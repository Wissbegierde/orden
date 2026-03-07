import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Modelo de fortaleza
// ─────────────────────────────────────────────────────────────────────────────

enum _Fortaleza { vacia, debil, media, fuerte, muyFuerte }

extension _FortalezaExt on _Fortaleza {
  String get etiqueta => switch (this) {
        _Fortaleza.vacia => '',
        _Fortaleza.debil => 'Débil',
        _Fortaleza.media => 'Regular',
        _Fortaleza.fuerte => 'Fuerte',
        _Fortaleza.muyFuerte => 'Muy fuerte',
      };

  Color get color => switch (this) {
        _Fortaleza.vacia => Colors.transparent,
        _Fortaleza.debil => AppColors.error,
        _Fortaleza.media => AppColors.warning,
        _Fortaleza.fuerte => AppColors.exito,
        _Fortaleza.muyFuerte => const Color(0xFF059669),
      };

  int get segmentosActivos => switch (this) {
        _Fortaleza.vacia => 0,
        _Fortaleza.debil => 1,
        _Fortaleza.media => 2,
        _Fortaleza.fuerte => 3,
        _Fortaleza.muyFuerte => 4,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
//  Lógica de puntuación
// ─────────────────────────────────────────────────────────────────────────────

_Fortaleza _calcularFortaleza(String password) {
  if (password.isEmpty) return _Fortaleza.vacia;

  int puntos = 0;
  // ✅ Umbral base aumentado a 8 (en línea con la nueva política mínima)
  if (password.length >= 8) puntos++;
  if (password.length >= 12) puntos++;
  if (password.contains(RegExp(r'[A-Z]'))) puntos++;
  if (password.contains(RegExp(r'[0-9]'))) puntos++;
  if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\/]'))) {
    puntos++;
  }

  return switch (puntos) {
    0 || 1 => _Fortaleza.debil,
    2 => _Fortaleza.media,
    3 => _Fortaleza.fuerte,
    _ => _Fortaleza.muyFuerte,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────

/// Barra visual de fortaleza de contraseña en tiempo real.
///
/// Actualizado: usa [Color.withValues(alpha:)] en lugar de [withOpacity()].
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final fortaleza = _calcularFortaleza(password);
    if (fortaleza == _Fortaleza.vacia) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              final activo = i < fortaleza.segmentosActivos;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: activo ? fortaleza.color : AppColors.borde,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: fortaleza.color,
            ),
            child: Text(fortaleza.etiqueta),
          ),
        ],
      ),
    );
  }
}
