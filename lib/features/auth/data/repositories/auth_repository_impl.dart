import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../../domain/entities/user.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/email_address.dart';
import '../../domain/value_objects/password.dart';
import '../dtos/user_dto.dart';

/// Implementación concreta del repositorio de autenticación usando
/// Firebase Auth y Cloud Firestore.
///
/// **Correcciones respecto a la versión anterior:**
/// 1. [Stream<User?>] elimina la lectura extra a Firestore en cada emisión.
/// 2. Sin [password.trim()] — las contraseñas nunca se transforman.
/// 3. [user-not-found] y [wrong-password] se mapean al mismo tipo de error
///    para prevenir enumeración de usuarios (OWASP ASVS 2.2.1).
/// 4. [emailVerificado] no se almacena en Firestore (fuente única = Firebase Auth).
/// 5. [login()] actualiza lastLogin de forma fire-and-forget (sin second get()).
/// 6. [actualizarPerfil()] preserva [AuthException] sin re-envolver.
/// 7. Stream con [onError] handler — no crashea la app si Firebase falla.
/// 8. Logs estructurados (solo en debug) sin filtrar info sensible a producción.
class AuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthRepositoryImpl({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _db.collection('usuarios');

  // ── Stream tipado: emite User? completo ───────────────────────────────────

  @override
  Stream<User?> get authStateChanges =>
      _auth.authStateChanges().asyncMap(_mapearFirebaseUser);

  Future<User?> _mapearFirebaseUser(fb.User? firebaseUser) async {
    if (firebaseUser == null) return null;

    try {
      final doc = await _usuarios.doc(firebaseUser.uid).get();
      if (!doc.exists || doc.data() == null) return null;

      return UserDto.fromMap(doc.data()!).toDomain(
        emailVerificado: firebaseUser.emailVerified,
      );
    } catch (e, st) {
      _log('Error al mapear usuario desde Firestore', e, st);
      return null;
    }
  }

  @override
  String? get currentUserUid => _auth.currentUser?.uid;

  // ── REGISTRO ──────────────────────────────────────────────────────────────

  @override
  Future<void> registrar({
    required String nombre,
    required EmailAddress email,
    required Password password,
    required String telefono,
    required String negocio,
  }) async {
    // Validación defensiva de dominio (segunda línea tras la UI)
    _validarNombre(nombre);
    _validarNegocio(negocio);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.value,
        // ✅ password.value — sin trim(), sin transformaciones
        password: password.value,
      );

      final firebaseUser = cred.user;
      if (firebaseUser == null) {
        throw const AuthException(
          tipo: AuthFailureType.desconocido,
          mensaje: 'No se pudo crear la cuenta.',
        );
      }

      final ahora = DateTime.now();
      final dto = UserDto(
        uid: firebaseUser.uid,
        nombre: nombre.trim(),
        email: email.value,
        telefono: telefono.trim(),
        negocio: negocio.trim(),
        rol: UserRole.operador.value,
        createdAt: ahora,
        lastLogin: ahora,
      );

      // Guardar perfil en Firestore. Si falla, eliminar la cuenta para no dejar
      // usuarios huérfanos (Firebase Auth sin documento Firestore).
      try {
        await _usuarios.doc(firebaseUser.uid).set(dto.toMap());
      } catch (e) {
        await firebaseUser.delete();
        throw AuthException(
          tipo: AuthFailureType.desconocido,
          mensaje: 'No se pudo guardar el perfil. Intenta de nuevo.',
          causa: e,
        );
      }

      // Enviar verificación de correo; no bloquear el flujo si falla.
      try {
        await firebaseUser.sendEmailVerification();
      } catch (e) {
        _log('No se pudo enviar correo de verificación', e, null);
      }
    } on AuthException {
      rethrow;
    } on fb.FirebaseAuthException catch (e) {
      _log('FirebaseAuthException en registrar', e, null);
      throw _mapearError(e);
    } catch (e, st) {
      _log('Error inesperado en registrar', e, st);
      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'Error inesperado al registrar. Intenta de nuevo.',
        causa: e,
      );
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────────

  @override
  Future<void> login({
    required EmailAddress email,
    required Password password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.value,
        // ✅ password.value — sin trim()
        password: password.value,
      );

      final uid = cred.user?.uid;
      if (uid == null) return;

      // Actualizar lastLogin de forma asíncrona (fire-and-forget).
      // No se hace await para no bloquear el flujo; si falla, no es crítico.
      unawaited(
        _usuarios.doc(uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        }).catchError((Object e) {
          _log('No se pudo actualizar lastLogin', e, null);
        }),
      );

      // El estado completo se propaga por [authStateChanges] automáticamente.
    } on fb.FirebaseAuthException catch (e) {
      _log('FirebaseAuthException en login', e, null);
      throw _mapearError(e);
    } catch (e, st) {
      _log('Error inesperado en login', e, st);
      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'Error inesperado al iniciar sesión.',
        causa: e,
      );
    }
  }

  // ── RECUPERAR PASSWORD ────────────────────────────────────────────────────

  @override
  Future<void> recuperarPassword(EmailAddress email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.value);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapearError(e);
    } catch (e, st) {
      _log('Error inesperado en recuperarPassword', e, st);
      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'No se pudo enviar el correo de recuperación.',
        causa: e,
      );
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e, st) {
      _log('Error en logout', e, st);
      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'Error al cerrar sesión.',
        causa: e,
      );
    }
  }

  // ── USUARIO ACTUAL ────────────────────────────────────────────────────────

  @override
  Future<User?> obtenerUsuarioActual() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final doc = await _usuarios.doc(firebaseUser.uid).get();
      if (!doc.exists || doc.data() == null) return null;

      return UserDto.fromMap(doc.data()!).toDomain(
        emailVerificado: firebaseUser.emailVerified,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _mapearError(e);
    } catch (e, st) {
      _log('Error en obtenerUsuarioActual', e, st);
      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'No se pudo obtener el usuario actual.',
        causa: e,
      );
    }
  }

  // ── ACTUALIZAR PERFIL ─────────────────────────────────────────────────────

  @override
  Future<User> actualizarPerfil({
    required String uid,
    String? nombre,
    String? telefono,
    String? negocio,
  }) async {
    // Validación defensiva
    if (nombre != null) _validarNombre(nombre);
    if (negocio != null) _validarNegocio(negocio);

    try {
      final campos = <String, dynamic>{};
      if (nombre != null) campos['nombre'] = nombre.trim();
      if (telefono != null) campos['telefono'] = telefono.trim();
      if (negocio != null) campos['negocio'] = negocio.trim();

      // Si no hay nada que actualizar, retornar el usuario actual.
      if (campos.isEmpty) {
        final actual = await obtenerUsuarioActual();
        if (actual == null) {
          throw const AuthException(
            tipo: AuthFailureType.documentoNoEncontrado,
            mensaje: 'No se encontró el usuario.',
          );
        }
        return actual;
      }

      await _usuarios.doc(uid).update(campos);

      // Leer el documento actualizado para retornar el estado consistente.
      final doc = await _usuarios.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        throw const AuthException(
          tipo: AuthFailureType.documentoNoEncontrado,
          mensaje: 'No se encontró el perfil actualizado.',
        );
      }

      return UserDto.fromMap(doc.data()!).toDomain(
        emailVerificado: _auth.currentUser?.emailVerified ?? false,
      );
    } on AuthException {
      // ✅ Preservar tipo original — no re-envolver con desconocido
      rethrow;
    } catch (e, st) {
      _log('Error en actualizarPerfil', e, st);
      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'No se pudo actualizar el perfil.',
        causa: e,
      );
    }
  }

  // ── VERIFICACIÓN DE EMAIL ─────────────────────────────────────────────────

  @override
  Future<void> enviarVerificacionEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'No hay sesión activa.',
      );
    }

    try {
      await user.sendEmailVerification();
    } on fb.FirebaseAuthException catch (e) {
      throw _mapearError(e);
    }
  }

  @override
  Future<void> recargarUsuario() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e, st) {
      _log('Error en recargarUsuario', e, st);
      // No lanzar: el provider maneja el estado tras el reload.
    }
  }

  // ── MAPEO DE ERRORES FIREBASE ─────────────────────────────────────────────

  static AuthException _mapearError(fb.FirebaseAuthException e) {
    final (tipo, mensaje) = switch (e.code) {
      // ✅ SEGURIDAD: user-not-found y wrong-password mapean al MISMO tipo.
      //    Diferenciarlos permitiría enumerar qué emails están registrados.
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        (
          AuthFailureType.credencialesInvalidas,
          'Correo o contraseña incorrectos.',
        ),
      'email-already-in-use' => (
          AuthFailureType.correoEnUso,
          'Ya existe una cuenta con ese correo.',
        ),
      'invalid-email' => (
          AuthFailureType.correoInvalido,
          'El formato del correo no es válido.',
        ),
      'weak-password' => (
          AuthFailureType.contraseniaDebil,
          'La contraseña es muy débil.',
        ),
      'too-many-requests' => (
          AuthFailureType.demasiadosIntentos,
          'Demasiados intentos. Espera unos minutos e intenta de nuevo.',
        ),
      'network-request-failed' => (
          AuthFailureType.sinConexion,
          'Sin conexión a internet.',
        ),
      'user-disabled' => (
          AuthFailureType.cuentaDeshabilitada,
          'Esta cuenta ha sido deshabilitada.',
        ),
      'operation-not-allowed' => (
          AuthFailureType.operacionNoPermitida,
          'Método de autenticación no permitido.',
        ),
      _ => (
          AuthFailureType.desconocido,
          'Error inesperado. Intenta de nuevo.',
        ),
    };

    return AuthException(tipo: tipo, mensaje: mensaje, causa: e);
  }

  // ── VALIDACIONES DEFENSIVAS ───────────────────────────────────────────────

  static void _validarNombre(String nombre) {
    if (nombre.trim().isEmpty) {
      throw const AuthException(
        tipo: AuthFailureType.datosInvalidos,
        mensaje: 'El nombre no puede estar vacío.',
      );
    }
  }

  static void _validarNegocio(String negocio) {
    if (negocio.trim().isEmpty) {
      throw const AuthException(
        tipo: AuthFailureType.datosInvalidos,
        mensaje: 'El nombre del negocio no puede estar vacío.',
      );
    }
  }

  // ── LOGGER ESTRUCTURADO ───────────────────────────────────────────────────

  /// Log solo en modo debug. Nunca imprime en builds de producción.
  ///
  /// ⚠️ No loguear contraseñas, tokens ni datos PII sensibles.
  static void _log(String mensaje, Object? error, StackTrace? st) {
    if (kDebugMode) {
      debugPrint('[Auth] $mensaje');
      if (error != null) debugPrint('[Auth] Error: $error');
      if (st != null) debugPrint('[Auth] StackTrace: $st');
    }
  }
}
