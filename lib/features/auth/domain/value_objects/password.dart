import 'package:flutter/foundation.dart';
import '../exceptions/auth_exception.dart';

/// Value object que encapsula una contraseña validada.
///
/// **SEGURIDAD CRÍTICA:**
/// - **Nunca aplica trim()** ni ninguna transformación silenciosa.
///   Un espacio intencional en la contraseña es parte de la contraseña.
/// - El valor se almacena solo en memoria durante el flujo de autenticación;
///   nunca se persiste ni se serializa.
///
/// Política mínima (OWASP ASVS 2.1.1 adaptada):
/// - Mínimo 8 caracteres.
/// - No se exige complejidad obligatoria (se guía con [PasswordStrengthIndicator]).
@immutable
class Password {
  static const int minLength = 8;

  /// Valor exacto ingresado por el usuario. Sin transformaciones.
  final String value;

  const Password._(this.value);

  /// Construye y valida la contraseña. Lanza [AuthException] si no cumple.
  factory Password(String raw) {
    // ⚠️ NO hay trim() aquí. Los espacios son parte de la contraseña.
    if (raw.length < minLength) {
      throw AuthException(
        tipo: AuthFailureType.contraseniaDebil,
        mensaje: 'La contraseña debe tener al menos $minLength caracteres.',
      );
    }

    return Password._(raw);
  }

  /// Construye sin validar — para login (donde el servidor decide si es válida).
  ///
  /// Solo aplica el check de vacío para evitar llamadas inútiles a Firebase.
  factory Password.login(String raw) {
    if (raw.isEmpty) {
      throw const AuthException(
        tipo: AuthFailureType.contraseniaDebil,
        mensaje: 'Ingresa tu contraseña.',
      );
    }
    return Password._(raw);
  }

  @override
  String toString() => '***'; // Nunca imprimir la contraseña en logs.

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Password && other.value == value);

  @override
  int get hashCode => value.hashCode;
}
