import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

/// DTO (Data Transfer Object) para la serialización/deserialización de [User]
/// hacia y desde Firestore.
///
/// **Responsabilidad única:** traducir entre el modelo de dominio puro [User]
/// y el mapa de Firestore que usa tipos de infraestructura como [Timestamp].
///
/// Este archivo es el **único lugar** en el proyecto que importa Firestore
/// para trabajar con datos de usuario, cumpliendo la regla de dependencia
/// de Clean Architecture.
class UserDto {
  final String uid;
  final String nombre;
  final String email;
  final String telefono;
  final String negocio;
  final String rol;
  final DateTime createdAt;
  final DateTime lastLogin;

  // ⚠️ emailVerificado NO se almacena en Firestore.
  // La fuente de verdad es Firebase Auth (FirebaseUser.emailVerified).
  // Almacenarlo generaría una segunda fuente manipulable.

  const UserDto({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.negocio,
    required this.rol,
    required this.createdAt,
    required this.lastLogin,
  });

  // ── Desde Firestore ────────────────────────────────────────────────────────

  factory UserDto.fromMap(Map<String, dynamic> map) => UserDto(
        uid: map['uid'] as String? ?? '',
        nombre: map['nombre'] as String? ?? '',
        email: map['email'] as String? ?? '',
        telefono: map['telefono'] as String? ?? '',
        negocio: map['negocio'] as String? ?? '',
        rol: map['rol'] as String? ?? UserRole.operador.value,
        createdAt:
            (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLogin:
            (map['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  // ── Hacia Firestore ────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'nombre': nombre.trim(),
        'email': email.trim().toLowerCase(),
        'telefono': telefono.trim(),
        'negocio': negocio.trim(),
        'rol': rol,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLogin': Timestamp.fromDate(lastLogin),
        // emailVerificado no se persiste aquí
      };

  // ── Conversión a dominio ───────────────────────────────────────────────────

  /// Convierte a entidad de dominio [User].
  ///
  /// [emailVerificado] se inyecta desde Firebase Auth, nunca desde Firestore.
  User toDomain({required bool emailVerificado}) => User(
        uid: uid,
        nombre: nombre,
        email: email,
        telefono: telefono,
        negocio: negocio,
        rol: UserRoleX.fromString(rol),
        emailVerificado: emailVerificado,
        createdAt: createdAt,
        lastLogin: lastLogin,
      );

  // ── Desde dominio ──────────────────────────────────────────────────────────

  factory UserDto.fromDomain(User user) => UserDto(
        uid: user.uid,
        nombre: user.nombre,
        email: user.email,
        telefono: user.telefono,
        negocio: user.negocio,
        rol: user.rol.value,
        createdAt: user.createdAt,
        lastLogin: user.lastLogin,
      );
}
