/// Tipos de fallo de autenticación, completamente independientes de Firebase.
///
/// **SEGURIDAD**: Se eliminó [usuarioNoEncontrado] de forma deliberada.
/// Diferenciarlo de [credencialesInvalidas] permitiría a un atacante enumerar
/// qué correos están registrados. Ambos casos se mapean a [credencialesInvalidas].
enum AuthFailureType {
  /// Credenciales incorrectas (email o contraseña). Mensaje siempre genérico.
  credencialesInvalidas,

  /// El correo ya tiene una cuenta registrada.
  correoEnUso,

  /// Formato de correo inválido.
  correoInvalido,

  /// La contraseña no cumple la política mínima.
  contraseniaDebil,

  /// Demasiados intentos fallidos consecutivos.
  demasiadosIntentos,

  /// Sin conectividad de red.
  sinConexion,

  /// La cuenta ha sido deshabilitada por un administrador.
  cuentaDeshabilitada,

  /// Método de autenticación no habilitado en Firebase Console.
  operacionNoPermitida,

  /// El usuario aún no verificó su correo electrónico.
  correoNoVerificado,

  /// Perfil no encontrado en Firestore (cuenta huérfana).
  documentoNoEncontrado,

  /// Los datos de entrada no superan la validación de dominio.
  datosInvalidos,

  /// Error no clasificado.
  desconocido,
}

/// Excepción de dominio para todos los fallos de autenticación.
///
/// La UI y el provider **solo** manejan [AuthException], nunca
/// [FirebaseAuthException] ni ningún error de infraestructura.
///
/// [causa] preserva el error original para logging interno; nunca se expone
/// en mensajes al usuario.
class AuthException implements Exception {
  final AuthFailureType tipo;
  final String mensaje;
  final Object? causa;

  const AuthException({
    required this.tipo,
    required this.mensaje,
    this.causa,
  });

  @override
  String toString() => 'AuthException[$tipo]: $mensaje';
}
