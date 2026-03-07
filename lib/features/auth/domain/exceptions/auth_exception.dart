/// Tipos de fallo de autenticación, completamente independientes de Firebase.
/// Permite cambiar el proveedor de auth sin modificar ni la UI ni el provider.
enum AuthFailureType {
  usuarioNoEncontrado,
  credencialesInvalidas,
  correoEnUso,
  correoInvalido,
  contraseniaDebil,
  demasiadosIntentos,
  sinConexion,
  cuentaDeshabilitada,
  operacionNoPermitida,
  correoNoVerificado,
  documentoNoEncontrado,
  desconocido,
}

/// Excepción de dominio para todos los fallos de autenticación.
/// La UI y el provider solo manejan [AuthException], nunca [FirebaseAuthException].
class AuthException implements Exception {
  final AuthFailureType tipo;
  final String mensaje;

  /// Causa original (puede ser [FirebaseAuthException] u otro error).
  final Object? causa;

  const AuthException({
    required this.tipo,
    required this.mensaje,
    this.causa,
  });

  @override
  String toString() => 'AuthException[$tipo]: $mensaje';
}
