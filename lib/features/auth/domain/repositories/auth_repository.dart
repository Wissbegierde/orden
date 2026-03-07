import '../models/user_model.dart';

/// Contrato del repositorio de autenticación.
///
/// **Regla de oro**: esta interfaz no importa nada de Firebase.
/// Eso garantiza que toda la lógica de negocio (provider, tests) sea
/// independiente del proveedor de auth y pueda mockearse sin Firebase.
///
/// Los errores se comunican lanzando [AuthException] (ver domain/exceptions).
abstract class AuthRepository {
  // ── Observación del estado de sesión ──────────────────────────

  /// Emite [true] cuando hay sesión activa y [false] al cerrar sesión.
  /// Se recomienda escuchar este stream durante todo el ciclo de vida de la app.
  Stream<bool> get authStateChanges;

  /// UID del usuario actualmente autenticado, o [null] si no hay sesión.
  String? get currentUserUid;

  // ── Operaciones de autenticación ──────────────────────────────

  /// Crea una cuenta nueva en Firebase Auth y guarda el perfil en Firestore.
  /// También envía el correo de verificación automáticamente.
  Future<UserModel> registrar({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
    required String negocio,
  });

  /// Inicia sesión con email y contraseña.
  /// Actualiza [lastLogin] en Firestore al autenticarse.
  Future<UserModel> login({
    required String email,
    required String password,
  });

  /// Envía un correo de restablecimiento de contraseña al [email] indicado.
  Future<void> recuperarPassword(String email);

  /// Cierra la sesión del usuario actual.
  Future<void> logout();

  // ── Gestión del perfil ─────────────────────────────────────────

  /// Obtiene el [UserModel] del usuario autenticado desde Firestore.
  /// Retorna [null] si no hay sesión activa o el documento no existe.
  Future<UserModel?> obtenerUsuarioActual();

  /// Actualiza los campos de perfil indicados en Firestore.
  /// Solo se actualizan los campos no nulos.
  Future<UserModel> actualizarPerfil({
    required String uid,
    String? nombre,
    String? telefono,
    String? negocio,
  });

  // ── Verificación de correo ─────────────────────────────────────

  /// Envía (o reenvía) el correo de verificación al usuario autenticado.
  Future<void> enviarVerificacionEmail();

  /// Recarga el usuario de Firebase para reflejar cambios remotos
  /// (p. ej., si el usuario verificó su correo en otro dispositivo).
  Future<void> recargarUsuario();
}
