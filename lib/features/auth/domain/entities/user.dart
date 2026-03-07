import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Rol de usuario
// ─────────────────────────────────────────────────────────────────────────────

enum UserRole { admin, operador }

extension UserRoleX on UserRole {
  String get value => name; // 'admin' | 'operador'

  static UserRole fromString(String? raw) => UserRole.values.firstWhere(
        (r) => r.name == raw,
        orElse: () => UserRole.operador,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Entidad de dominio
// ─────────────────────────────────────────────────────────────────────────────

/// Entidad inmutable del usuario autenticado.
///
/// **Reglas de capa:**
/// - No importa ningún SDK externo (Firebase, Firestore, etc.).
/// - Los tipos de fecha son [DateTime] Dart puro.
/// - La serialización Firestore (Timestamp) vive únicamente en [UserDto].
///
/// **Igualdad:** por [uid], que es la clave primaria del sistema.
@immutable
class User {
  final String uid;
  final String nombre;
  final String email;
  final String telefono;
  final String negocio;
  final UserRole rol;

  /// Estado de verificación de correo.
  ///
  /// **Fuente de verdad única:** Firebase Auth ([FirebaseUser.emailVerified]).
  /// Este campo se rellena al leer desde la capa data y **nunca** se persiste
  /// en Firestore para evitar una segunda fuente de verdad manipulable.
  final bool emailVerificado;

  final DateTime createdAt;
  final DateTime lastLogin;

  const User({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.negocio,
    this.rol = UserRole.operador,
    this.emailVerificado = false,
    required this.createdAt,
    required this.lastLogin,
  });

  // ── copyWith ───────────────────────────────────────────────────────────────

  User copyWith({
    String? nombre,
    String? email,
    String? telefono,
    String? negocio,
    UserRole? rol,
    bool? emailVerificado,
    DateTime? lastLogin,
  }) =>
      User(
        uid: uid,
        nombre: nombre ?? this.nombre,
        email: email ?? this.email,
        telefono: telefono ?? this.telefono,
        negocio: negocio ?? this.negocio,
        rol: rol ?? this.rol,
        emailVerificado: emailVerificado ?? this.emailVerificado,
        createdAt: createdAt,
        lastLogin: lastLogin ?? this.lastLogin,
      );

  // ── Igualdad por uid ───────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() =>
      'User(uid: $uid, email: $email, negocio: $negocio, rol: ${rol.value})';
}
