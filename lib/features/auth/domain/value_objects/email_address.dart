import 'package:flutter/foundation.dart';
import '../exceptions/auth_exception.dart';

/// Value object que encapsula un correo electrónico validado y normalizado.
///
/// La construcción lanza [AuthException] si el formato es inválido, garantizando
/// que **ningún correo malformado** pueda propagarse hacia la capa de datos.
///
/// Normalización: recorte de espacios + minúsculas (RFC 5321 §2.4).
@immutable
class EmailAddress {
  /// Valor normalizado (trim + toLowerCase). Nunca nulo ni vacío.
  final String value;

  const EmailAddress._(this.value);

  /// Construye y valida el correo. Lanza [AuthException] si es inválido.
  factory EmailAddress(String raw) {
    final normalized = raw.trim().toLowerCase();

    if (normalized.isEmpty) {
      throw const AuthException(
        tipo: AuthFailureType.correoInvalido,
        mensaje: 'El correo no puede estar vacío.',
      );
    }

    if (!_regex.hasMatch(normalized)) {
      throw const AuthException(
        tipo: AuthFailureType.correoInvalido,
        mensaje: 'El formato del correo no es válido.',
      );
    }

    return EmailAddress._(normalized);
  }

  // RFC 5322 simplificado — suficiente para UX; Firebase hace la validación final.
  static final _regex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EmailAddress && other.value == value);

  @override
  int get hashCode => value.hashCode;
}
