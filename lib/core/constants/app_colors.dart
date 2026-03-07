import 'package:flutter/material.dart';

/// Paleta de colores centralizada para toda la app Orden.
///
/// **Reglas de uso**:
/// - Nunca hardcodear colores hex fuera de este archivo.
/// - Para variantes de opacidad usa `.withOpacity()` en el punto de uso,
///   no crear nuevas constantes aquí (evita explosión de nombres).
/// - Los alias de compatibilidad (`azulPrimario`, `dorado`) se mantienen
///   para no romper código de módulos anteriores mientras se migra.
class AppColors {
  AppColors._();

  // ── Marca ────────────────────────────────────────────────────
  static const Color primario = Color(0xFF4F46E5);
  static const Color primarioOscuro = Color(0xFF3730A3);
  static const Color secundario = Color(0xFF7C3AED);

  // Gradiente del header de autenticación
  static const LinearGradient gradienteHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );

  // ── Superficie y fondo ────────────────────────────────────────
  static const Color fondo = Color(0xFFF4F6F9);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color borde = Color(0xFFE5E7EB);

  // ── Semánticos ────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color exito = Color(0xFF10B981);

  /// Amarillo-naranja usado en el indicador de contraseña "regular".
  static const Color warning = Color(0xFFF59E0B);

  static const Color textoOscuro = Color(0xFF1E1B4B);
  static const Color textoGris = Color(0xFF6B7280);

  // ── Alias de compatibilidad con módulos anteriores ────────────
  /// Usar [primario] en código nuevo.
  static const Color azulPrimario = primario;

  /// Usar [primarioOscuro] en código nuevo.
  static const Color azulOscuro = primarioOscuro;

  /// Históricamente mapeado a [exito] (verde). Usar [exito] en código nuevo.
  static const Color dorado = exito;
}
