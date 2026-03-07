import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/user.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/email_address.dart';
import '../../domain/value_objects/password.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Estados del ciclo de autenticación
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStatus {
  /// Verificando si hay sesión guardada al iniciar la app.
  inicial,

  /// Operación asíncrona en curso.
  cargando,

  /// Sesión activa y perfil de usuario disponible.
  autenticado,

  /// Sin sesión activa (logout o primer uso).
  noAutenticado,

  /// La última operación falló; [AuthProvider.errorMessage] contiene el detalle.
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
//  Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Gestiona el estado global de autenticación y expone acciones a la UI.
///
/// **Mejoras respecto a la versión anterior:**
/// - Constructor requiere [AuthRepository] explícito (DI estricta, testeable).
/// - Suscripción a [Stream<User?>] — no se necesita leer Firestore por separado.
/// - [onError] en el stream — no crashea la app si Firebase emite un error.
/// - [correoVerificacionEnviado] se resetea al cerrar sesión.
/// - [limpiarError] restaura el estado coherente preservando el usuario cacheado.
/// - [recargarUsuario] y [actualizarPerfil] actualizan el caché en memoria.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  StreamSubscription<User?>? _authSub;

  // ── Estado ─────────────────────────────────────────────────────────────────

  AuthStatus _status = AuthStatus.inicial;
  User? _usuario;
  String? _errorMessage;
  bool _correoVerificacionEnviado = false;

  // ── Getters públicos ───────────────────────────────────────────────────────

  AuthStatus get status => _status;
  User? get usuario => _usuario;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.cargando;
  bool get isAutenticado => _status == AuthStatus.autenticado;
  bool get correoVerificacionEnviado => _correoVerificacionEnviado;

  // ── Constructor ─────────────────────────────────────────────────────────────

  /// Requiere una instancia de [AuthRepository].
  ///
  /// **Diseño intencional:** no hay valor por defecto. El punto de composición
  /// (main.dart o un ChangeNotifierProvider en el árbol de widgets) inyecta
  /// [AuthRepositoryImpl]. Esto garantiza que los tests puedan inyectar un mock
  /// sin modificar este provider.
  ///
  /// Ejemplo de registro en main.dart:
  /// ```dart
  /// ChangeNotifierProvider(
  ///   create: (_) => AuthProvider(repo: AuthRepositoryImpl()),
  /// )
  /// ```
  AuthProvider({required AuthRepository repo}) : _repo = repo {
    _escucharCambiosDeAuth();
  }

  // ── Stream de autenticación ────────────────────────────────────────────────

  void _escucharCambiosDeAuth() {
    _authSub = _repo.authStateChanges.listen(
      _handleAuthChange,
      // ✅ onError: el stream nunca crashea la app silenciosamente
      onError: (Object error, StackTrace st) {
        if (kDebugMode) debugPrint('[AuthProvider] Stream error: $error');
        _setError('Error de sesión. Reinicia la aplicación.');
      },
    );
  }

  void _handleAuthChange(User? user) {
    _usuario = user;
    _status = user != null ? AuthStatus.autenticado : AuthStatus.noAutenticado;

    // Resetear flags de sesión anterior al cerrar sesión
    if (user == null) {
      _correoVerificacionEnviado = false;
    }

    notifyListeners();
  }

  // ── Registro ───────────────────────────────────────────────────────────────

  Future<bool> registrar({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
    required String negocio,
  }) async {
    _iniciarCarga();
    try {
      // Value objects validan antes de llegar al repositorio
      final emailVO = EmailAddress(email);
      final passVO = Password(password);

      await _repo.registrar(
        nombre: nombre,
        email: emailVO,
        password: passVO,
        telefono: telefono,
        negocio: negocio,
      );

      // El stream actualiza _usuario y _status automáticamente.
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.mensaje);
      return false;
    } catch (_) {
      _setError('Error inesperado. Intenta de nuevo.');
      return false;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _iniciarCarga();
    try {
      final emailVO = EmailAddress(email);
      final passVO = Password.login(password);

      await _repo.login(email: emailVO, password: passVO);

      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.mensaje);
      return false;
    } catch (_) {
      _setError('Error inesperado. Intenta de nuevo.');
      return false;
    }
  }

  // ── Recuperar contraseña ───────────────────────────────────────────────────

  Future<bool> recuperarPassword(String email) async {
    _iniciarCarga();
    try {
      final emailVO = EmailAddress(email);
      await _repo.recuperarPassword(emailVO);

      _status = AuthStatus.noAutenticado;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.mensaje);
      return false;
    } catch (_) {
      _setError('No se pudo enviar el correo. Intenta de nuevo.');
      return false;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {
      // Si Firebase falla al cerrar sesión, forzar el estado local.
    } finally {
      _usuario = null;
      _status = AuthStatus.noAutenticado;
      _errorMessage = null;
      _correoVerificacionEnviado = false;
      notifyListeners();
    }
  }

  // ── Actualizar perfil ──────────────────────────────────────────────────────

  Future<bool> actualizarPerfil({
    String? nombre,
    String? telefono,
    String? negocio,
  }) async {
    final uid = _usuario?.uid;
    if (uid == null) return false;

    _iniciarCarga();
    try {
      final updated = await _repo.actualizarPerfil(
        uid: uid,
        nombre: nombre,
        telefono: telefono,
        negocio: negocio,
      );

      // Actualizar caché en memoria
      _usuario = updated;
      _status = AuthStatus.autenticado;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.mensaje);
      return false;
    } catch (_) {
      _setError('No se pudo actualizar el perfil.');
      return false;
    }
  }

  // ── Verificación de correo ─────────────────────────────────────────────────

  Future<bool> enviarVerificacionEmail() async {
    _iniciarCarga();
    try {
      await _repo.enviarVerificacionEmail();

      _status = _usuario != null ? AuthStatus.autenticado : AuthStatus.noAutenticado;
      _correoVerificacionEnviado = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.mensaje);
      return false;
    } catch (_) {
      _setError('No se pudo enviar el correo de verificación.');
      return false;
    }
  }

  /// Recarga el usuario de Firebase y actualiza el caché en memoria.
  ///
  /// Tras el reload, el stream de Firebase emite automáticamente el estado
  /// actualizado. Este método fuerza la recarga cuando el stream no lo hace
  /// (p.ej. en el polling de verificación de email).
  Future<void> recargarUsuario() async {
    await _repo.recargarUsuario();
    try {
      final user = await _repo.obtenerUsuarioActual();
      if (user != null && user != _usuario) {
        _usuario = user;
        notifyListeners();
      }
    } catch (_) {
      // Silenciar: si falla la recarga, el estado anterior sigue siendo válido.
    }
  }

  // ── Utilidades ─────────────────────────────────────────────────────────────

  /// Descarta el mensaje de error y restaura el estado coherente.
  void limpiarError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _status = _usuario != null ? AuthStatus.autenticado : AuthStatus.noAutenticado;
      notifyListeners();
    }
  }

  // ── Helpers privados ───────────────────────────────────────────────────────

  void _iniciarCarga() {
    _status = AuthStatus.cargando;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
