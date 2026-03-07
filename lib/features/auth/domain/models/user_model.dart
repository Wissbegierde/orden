import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Rol de usuario
// ─────────────────────────────────────────────────────────────────────────────

/// Rol del usuario dentro del sistema Orden.
/// Extensible sin romper código existente: solo añadir valores al enum.
enum UserRole { admin, operador }

extension UserRoleExt on UserRole {
  String get valor => name; // 'admin' | 'operador'

  static UserRole fromString(String? value) => UserRole.values.firstWhere(
        (r) => r.name == value,
        orElse: () => UserRole.operador,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Modelo de usuario
// ─────────────────────────────────────────────────────────────────────────────

/// Modelo de dominio del usuario autenticado.
///
/// **Inmutable**: usa [copyWith] para producir versiones actualizadas.
/// No importa ningún SDK de Firebase; la serialización [toMap]/[fromMap]
/// trabaja con tipos Dart puros excepto [Timestamp] (específico de Firestore,
/// que vive solo en la capa de datos).
class UserModel {
  final String uid;
  final String nombre;
  final String email;
  final String telefono;
  final String negocio;
  final UserRole rol;

  /// Indica si el usuario confirmó su correo en Firebase Auth.
  final bool emailVerificado;

  final DateTime createdAt;
  final DateTime lastLogin;

  const UserModel({
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

  // ── Serialización ──────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nombre': nombre.trim(),
        'email': email.trim().toLowerCase(),
        'telefono': telefono.trim(),
        'negocio': negocio.trim(),
        'rol': rol.valor,
        'emailVerificado': emailVerificado,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLogin': Timestamp.fromDate(lastLogin),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] as String? ?? '',
        nombre: map['nombre'] as String? ?? '',
        email: map['email'] as String? ?? '',
        telefono: map['telefono'] as String? ?? '',
        negocio: map['negocio'] as String? ?? '',
        rol: UserRoleExt.fromString(map['rol'] as String?),
        emailVerificado: map['emailVerificado'] as bool? ?? false,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLogin:
            (map['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  // ── Utilidades ─────────────────────────────────────────────────

  /// Retorna una copia con los campos indicados reemplazados.
  /// Todos los parámetros son opcionales para mayor flexibilidad.
  UserModel copyWith({
    String? nombre,
    String? email,
    String? telefono,
    String? negocio,
    UserRole? rol,
    bool? emailVerificado,
    DateTime? lastLogin,
  }) =>
      UserModel(
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

  // ── Igualdad por identidad (uid) ───────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserModel && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, negocio: $negocio, rol: ${rol.valor})';
}
