import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Estados del ciclo de autenticación
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStatus {
  /// Estado inicial: verificando si hay sesión guardada en Firebase.
  inicial,

  /// Operación asíncrona en curso (login, registro, etc.).
  cargando,

  /// Sesión activa y datos de usuario cargados correctamente.
  autenticado,

  /// Sin sesión activa (logout o nunca autenticado).
  noAutenticado,

  /// Última operación terminó con error; [AuthProvider.errorMessage] contiene el detalle.
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
//  Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Gestiona el estado de autenticación y expone las acciones de auth a la UI.
///
/// **Garantías**:
/// - No importa nada de Firebase directamente (solo el repositorio abstracto).
/// - Cancela la suscripción al stream cuando el provider es destruido (sin memory leaks).
/// - Todas las operaciones de red manejan [AuthException] y actualizan el estado.
/// - [limpiarError] permite a la UI resetear el estado de error sin relanzar operaciones.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  /// Suscripción al stream de Firebase; se cancela en [dispose].
  StreamSubscription<bool>? _authSub;

  // ── Estado ─────────────────────────────────────────────────────

  AuthStatus _status = AuthStatus.inicial;
  UserModel? _usuario;
  String? _errorMessage;

  // Controla si el correo de verificación fue enviado recientemente
  bool _correoVerificacionEnviado = false;

  // ── Getters públicos ───────────────────────────────────────────

  AuthStatus get status => _status;
  UserModel? get usuario => _usuario;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.cargando;
  bool get isAutenticado => _status == AuthStatus.autenticado;
  bool get correoVerificacionEnviado => _correoVerificacionEnviado;

  // ── Constructor ────────────────────────────────────────────────

  AuthProvider({AuthRepository? repo})
      : _repo = repo ?? AuthRepositoryImpl() {
    _escucharCambiosDeAuth();
  }

  // ── Escuchar Firebase Auth (stream) ───────────────────────────

  /// Escucha cambios de sesión de Firebase en tiempo real.
  /// La suscripción se cancela automáticamente en [dispose].
  void _escucharCambiosDeAuth() {
    _authSub = _repo.authStateChanges.listen((haySession) async {
      if (haySession) {
        final user = await _repo.obtenerUsuarioActual();
        _usuario = user;
        _status = user != null ? AuthStatus.autenticado : AuthStatus.noAutenticado;
      } else {
        _usuario = null;
        _status = AuthStatus.noAutenticado;
      }
      notifyListeners();
    });
  }

  // ── Registro ───────────────────────────────────────────────────

  Future<bool> registrar({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
    required String negocio,
  }) async {
    _iniciarCarga();
    try {
      _usuario = await _repo.registrar(
        nombre: nombre,
        email: email,
        password: password,
        telefono: telefono,
        negocio: negocio,
      );
      _status = AuthStatus.autenticado;
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

  // ── Login ──────────────────────────────────────────────────────

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _iniciarCarga();
    try {
      _usuario = await _repo.login(email: email, password: password);
      _status = AuthStatus.autenticado;
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

  // ── Recuperar contraseña ───────────────────────────────────────

  Future<bool> recuperarPassword(String email) async {
    _iniciarCarga();
    try {
      await _repo.recuperarPassword(email);
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

  // ── Logout ─────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {
      // Si Firebase falla al cerrar sesión, forzar el estado local igualmente
    } finally {
      _usuario = null;
      _status = AuthStatus.noAutenticado;
      _errorMessage = null;
      _correoVerificacionEnviado = false;
      notifyListeners();
    }
  }

  // ── Actualizar perfil ──────────────────────────────────────────

  Future<bool> actualizarPerfil({
    String? nombre,
    String? telefono,
    String? negocio,
  }) async {
    final uid = _usuario?.uid;
    if (uid == null) return false;

    _iniciarCarga();
    try {
      _usuario = await _repo.actualizarPerfil(
        uid: uid,
        nombre: nombre,
        telefono: telefono,
        negocio: negocio,
      );
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

  // ── Verificación de correo ─────────────────────────────────────

  /// Envía (o reenvía) el correo de verificación al usuario autenticado.
  Future<bool> enviarVerificacionEmail() async {
    _iniciarCarga();
    try {
      await _repo.enviarVerificacionEmail();
      _status = isAutenticado ? AuthStatus.autenticado : AuthStatus.noAutenticado;
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

  /// Recarga el usuario de Firebase y actualiza el estado local.
  Future<void> recargarUsuario() async {
    await _repo.recargarUsuario();
    final user = await _repo.obtenerUsuarioActual();
    if (user != null) {
      _usuario = user;
      notifyListeners();
    }
  }

  // ── Utilidades ─────────────────────────────────────────────────

  /// Permite a la UI descartar el banner de error sin relanzar la operación.
  void limpiarError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // Restaurar estado coherente: si hay usuario, autenticado; si no, noAutenticado
      _status = _usuario != null ? AuthStatus.autenticado : AuthStatus.noAutenticado;
      notifyListeners();
    }
  }

  // ── Helpers privados ───────────────────────────────────────────

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

  // ── Dispose (cancelar suscripción al stream) ───────────────────

  @override
  void dispose() {
    // CRÍTICO: cancelar la suscripción para evitar memory leaks
    _authSub?.cancel();
    super.dispose();
  }
}
