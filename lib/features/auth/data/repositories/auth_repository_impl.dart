import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _db.collection('usuarios');

  @override
  Stream<bool> get authStateChanges =>
      _auth.authStateChanges().map((user) => user != null);

  @override
  String? get currentUserUid => _auth.currentUser?.uid;

  // ─────────────────────────────────────────────────────────────
  // REGISTRO
  // ─────────────────────────────────────────────────────────────

  @override
  Future<UserModel> registrar({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
    required String negocio,
  }) async {
    try {
      final emailLimpio = email.trim().toLowerCase();
      final pass = password.trim();

      if (emailLimpio.isEmpty) {
        throw AuthException(
          tipo: AuthFailureType.correoInvalido,
          mensaje: 'Debes ingresar un correo.',
        );
      }

      if (pass.length < 6) {
        throw AuthException(
          tipo: AuthFailureType.contraseniaDebil,
          mensaje: 'La contraseña debe tener mínimo 6 caracteres.',
        );
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailLimpio,
        password: pass,
      );

      final firebaseUser = cred.user;

      if (firebaseUser == null) {
        throw AuthException(
          tipo: AuthFailureType.desconocido,
          mensaje: 'No se pudo crear el usuario.',
        );
      }

      final uid = firebaseUser.uid;
      final ahora = DateTime.now();

      final user = UserModel(
        uid: uid,
        nombre: nombre.trim(),
        email: emailLimpio,
        telefono: telefono.trim(),
        negocio: negocio.trim(),
        rol: UserRole.operador,
        emailVerificado: false,
        createdAt: ahora,
        lastLogin: ahora,
      );

      try {
        await _usuarios.doc(uid).set(user.toMap());
      } catch (e) {
        await firebaseUser.delete();

        throw AuthException(
          tipo: AuthFailureType.desconocido,
          mensaje: 'No se pudo guardar el perfil del usuario.',
          causa: e,
        );
      }

      try {
        await firebaseUser.sendEmailVerification();
      } catch (e) {
        debugPrint("Error enviando verificación: $e");
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException: ${e.code}");
      debugPrint(e.message);

      throw _mapearError(e);
    } catch (e) {
      debugPrint("Error inesperado en registrar: $e");

      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'Error inesperado al registrar. Intenta de nuevo.',
        causa: e,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────────────────────

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final uid = cred.user!.uid;
      final ahora = DateTime.now();
      final emailVerificado = cred.user!.emailVerified;

      await _usuarios.doc(uid).update({
        'lastLogin': Timestamp.fromDate(ahora),
        'emailVerificado': emailVerificado,
      });

      final doc = await _usuarios.doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        throw AuthException(
          tipo: AuthFailureType.documentoNoEncontrado,
          mensaje: 'No se encontraron los datos de tu cuenta.',
        );
      }

      return UserModel.fromMap(doc.data()!);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException: ${e.code}");

      throw _mapearError(e);
    } catch (e) {
      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'Error inesperado al iniciar sesión.',
        causa: e,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RECUPERAR PASSWORD
  // ─────────────────────────────────────────────────────────────

  @override
  Future<void> recuperarPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
    } on FirebaseAuthException catch (e) {
      throw _mapearError(e);
    } catch (e) {
      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'No se pudo enviar el correo.',
        causa: e,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'Error al cerrar sesión.',
        causa: e,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // USUARIO ACTUAL
  // ─────────────────────────────────────────────────────────────

  @override
  Future<UserModel?> obtenerUsuarioActual() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final doc = await _usuarios.doc(firebaseUser.uid).get();

      if (!doc.exists || doc.data() == null) return null;

      final model = UserModel.fromMap(doc.data()!);

      if (model.emailVerificado != firebaseUser.emailVerified) {
        await _usuarios.doc(firebaseUser.uid).update({
          'emailVerificado': firebaseUser.emailVerified,
        });

        return model.copyWith(emailVerificado: firebaseUser.emailVerified);
      }

      return model;
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ACTUALIZAR PERFIL
  // ─────────────────────────────────────────────────────────────

  @override
  Future<UserModel> actualizarPerfil({
    required String uid,
    String? nombre,
    String? telefono,
    String? negocio,
  }) async {
    try {
      final campos = <String, dynamic>{};

      if (nombre != null) campos['nombre'] = nombre.trim();
      if (telefono != null) campos['telefono'] = telefono.trim();
      if (negocio != null) campos['negocio'] = negocio.trim();

      if (campos.isEmpty) {
        final actual = await obtenerUsuarioActual();

        if (actual == null) {
          throw AuthException(
            tipo: AuthFailureType.documentoNoEncontrado,
            mensaje: 'No se encontró el usuario.',
          );
        }

        return actual;
      }

      await _usuarios.doc(uid).update(campos);

      final doc = await _usuarios.doc(uid).get();

      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      throw AuthException(
        tipo: AuthFailureType.desconocido,
        mensaje: 'No se pudo actualizar el perfil.',
        causa: e,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // VERIFICACIÓN EMAIL
  // ─────────────────────────────────────────────────────────────

  @override
  Future<void> enviarVerificacionEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw AuthException(
        tipo: AuthFailureType.usuarioNoEncontrado,
        mensaje: 'No hay sesión activa.',
      );
    }

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _mapearError(e);
    }
  }

  @override
  Future<void> recargarUsuario() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────
  // MAPEO DE ERRORES FIREBASE
  // ─────────────────────────────────────────────────────────────

  static AuthException _mapearError(FirebaseAuthException e) {
    final (tipo, mensaje) = switch (e.code) {
      'user-not-found' => (
          AuthFailureType.usuarioNoEncontrado,
          'No existe una cuenta con ese correo.'
        ),
      'wrong-password' => (
          AuthFailureType.credencialesInvalidas,
          'Contraseña incorrecta.'
        ),
      'invalid-credential' => (
          AuthFailureType.credencialesInvalidas,
          'Correo o contraseña incorrectos.'
        ),
      'email-already-in-use' => (
          AuthFailureType.correoEnUso,
          'Ya existe una cuenta con ese correo.'
        ),
      'invalid-email' => (
          AuthFailureType.correoInvalido,
          'El formato del correo no es válido.'
        ),
      'weak-password' => (
          AuthFailureType.contraseniaDebil,
          'La contraseña es muy débil.'
        ),
      'too-many-requests' => (
          AuthFailureType.demasiadosIntentos,
          'Demasiados intentos fallidos.'
        ),
      'network-request-failed' => (
          AuthFailureType.sinConexion,
          'Sin conexión a internet.'
        ),
      'user-disabled' => (
          AuthFailureType.cuentaDeshabilitada,
          'Esta cuenta ha sido deshabilitada.'
        ),
      'operation-not-allowed' => (
          AuthFailureType.operacionNoPermitida,
          'Método de autenticación no permitido.'
        ),
      _ => (
          AuthFailureType.desconocido,
          'Error inesperado. Intenta de nuevo.'
        ),
    };

    return AuthException(tipo: tipo, mensaje: mensaje, causa: e);
  }
}
