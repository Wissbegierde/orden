/// Validadores reutilizables para formularios del proyecto Orden.
///
/// **Convenciones**:
/// - Retornan `null` si el valor es válido.
/// - Retornan `String` con el mensaje de error si el valor es inválido.
/// - Métodos `static` puros: no dependen de ningún estado externo.
///
/// **Separación login vs registro**:
/// - [passwordLogin]: solo verifica que el campo no esté vacío (la validez
///   real la comprueba Firebase). No muestra reglas estrictas al usuario.
/// - [passwordRegistro]: aplica reglas de fortaleza mínimas para cuentas nuevas.
class Validators {
  Validators._();

  // ── Campos de texto ───────────────────────────────────────────

  static String? nombre(String? val) {
    if (val == null || val.trim().isEmpty) return 'Ingresa tu nombre';
    if (val.trim().length < 3) return 'Mínimo 3 caracteres';
    if (val.trim().length > 60) return 'Máximo 60 caracteres';
    return null;
  }

  static String? negocio(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Ingresa el nombre del negocio';
    }
    if (val.trim().length < 2) return 'Mínimo 2 caracteres';
    if (val.trim().length > 80) return 'Máximo 80 caracteres';
    return null;
  }

  // ── Correo electrónico ────────────────────────────────────────

  static final _emailRegex =
      RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  static String? email(String? val) {
    if (val == null || val.trim().isEmpty) return 'Ingresa tu correo';
    if (!_emailRegex.hasMatch(val.trim())) {
      return 'Formato de correo inválido';
    }
    return null;
  }

  // ── Teléfono (opcional) ───────────────────────────────────────

  static String? telefono(String? val) {
    if (val == null || val.trim().isEmpty) return null; // campo opcional
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Número de teléfono inválido';
    }
    return null;
  }

  // ── Contraseñas ───────────────────────────────────────────────

  /// Validación ligera para el campo de contraseña en **login**.
  /// Firebase comprobará las credenciales reales; aquí solo evitamos
  /// enviar una petición con campo vacío.
  static String? passwordLogin(String? val) {
    if (val == null || val.isEmpty) return 'Ingresa tu contraseña';
    return null;
  }

  /// Validación estricta para **registro** de nueva contraseña.
  /// Exige mínimo 8 caracteres para alinearse con las mejores prácticas
  /// actuales (NIST SP 800-63B) y la configuración de Firebase Auth.
  static String? passwordRegistro(String? val) {
    if (val == null || val.isEmpty) return 'Ingresa una contraseña';
    if (val.length < 8) return 'Mínimo 8 caracteres';
    if (val.length > 128) return 'Contraseña demasiado larga';
    return null;
  }

  /// Mantiene compatibilidad con código existente que use [password].
  /// Internamente delega a [passwordRegistro].
  static String? password(String? val) => passwordRegistro(val);

  /// Validador de fábrica para el campo "confirmar contraseña".
  ///
  /// Captura el valor actual del campo principal en el momento de la llamada.
  /// El campo de confirmación llama a [_confirmFieldKey.currentState?.validate()]
  /// cada vez que el campo principal cambia para mantenerse sincronizado.
  static String? Function(String?) confirmarPassword(String original) {
    return (String? val) {
      if (val == null || val.isEmpty) return 'Confirma tu contraseña';
      if (val != original) return 'Las contraseñas no coinciden';
      return null;
    };
  }

  /// Alias semántico para recuperación de contraseña (misma lógica que [email]).
  static String? emailRecuperacion(String? val) => email(val);
}
