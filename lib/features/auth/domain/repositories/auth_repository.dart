import '../entities/user.dart';
import '../value_objects/email_address.dart';
import '../value_objects/password.dart';

/// Contrato del repositorio de autenticación.
///
/// **Reglas de capa (Dependency Rule):**
/// - Esta interfaz **no importa** nada de Firebase, Firestore ni ningún SDK.
/// - Todas las entradas y salidas usan tipos del dominio.
/// - Los errores se comunican lanzando [AuthException].
///
/// **Stream tipado [authStateChanges]:**
/// Emite [User] cuando hay sesión activa, o `null` al cerrar sesión.
/// La capa de presentación nunca necesita consultar Firestore por separado;
/// el stream propaga el modelo completo del usuario.
abstract interface class AuthRepository {
  // ── Observación del estado de sesión ──────────────────────────────────────

  /// Emite el [User] autenticado, o `null` si no hay sesión activa.
  ///
  /// Reemplaza el antiguo `Stream<bool>` que obligaba a lecturas adicionales
  /// a Firestore. El stream incluye los datos de perfil desde la primera emisión.
  Stream<User?> get authStateChanges;

  /// UID del usuario actualmente autenticado, o `null` si no hay sesión.
  String? get currentUserUid;

  // ── Operaciones de autenticación ──────────────────────────────────────────

  /// Registra un nuevo usuario en Firebase Auth y crea su perfil en Firestore.
  ///
  /// Envía el correo de verificación automáticamente tras el registro.
  /// El estado actualizado se propaga por [authStateChanges].
  Future<void> registrar({
    required String nombre,
    required EmailAddress email,
    required Password password,
    required String telefono,
    required String negocio,
  });

  /// Inicia sesión con email y contraseña.
  ///
  /// Actualiza [lastLogin] en Firestore de forma asíncrona (fire-and-forget)
  /// para no bloquear el flujo. El usuario se propaga por [authStateChanges].
  Future<void> login({
    required EmailAddress email,
    required Password password,
  });

  /// Envía un correo de restablecimiento de contraseña.
  Future<void> recuperarPassword(EmailAddress email);

  /// Cierra la sesión del usuario actual.
  Future<void> logout();

  // ── Gestión del perfil ────────────────────────────────────────────────────

  /// Obtiene el [User] actual desde Firestore. Retorna `null` si no hay sesión.
  ///
  /// Principalmente para restaurar estado al iniciar la app. Durante sesión
  /// activa el provider usa el valor cacheado desde [authStateChanges].
  Future<User?> obtenerUsuarioActual();

  /// Actualiza los campos de perfil indicados en Firestore.
  ///
  /// Solo actualiza los campos no nulos. Retorna el [User] actualizado.
  Future<User> actualizarPerfil({
    required String uid,
    String? nombre,
    String? telefono,
    String? negocio,
  });

  // ── Verificación de correo ────────────────────────────────────────────────

  /// Envía o reenvía el correo de verificación al usuario autenticado.
  Future<void> enviarVerificacionEmail();

  /// Recarga el token de Firebase para reflejar cambios remotos
  /// (p.ej. si el usuario verificó su correo en otro dispositivo).
  ///
  /// El estado actualizado se propagará por [authStateChanges].
  Future<void> recargarUsuario();
}
