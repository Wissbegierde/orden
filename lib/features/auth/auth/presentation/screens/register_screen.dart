import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/error_banner.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/section_label.dart';

/// Pantalla de registro de nuevo usuario.
///
/// **Cambios respecto a la versión anterior:**
/// - La contraseña se pasa directamente al provider sin transformaciones.
/// - La confirmación valida contra el texto exacto (sin trim).
/// - El validador de contraseña exige mínimo 8 caracteres (antes 6).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmFieldKey = GlobalKey<FormFieldState>();

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _negocioCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _nombreFocus = FocusNode();
  final _telefonoFocus = FocusNode();
  final _negocioFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  String _passwordActual = '';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _negocioCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _nombreFocus.dispose();
    _telefonoFocus.dispose();
    _negocioFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();

    await context.read<AuthProvider>().registrar(
          nombre: _nombreCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          // ✅ Sin trim() en la contraseña
          password: _passCtrl.text,
          telefono: _telefonoCtrl.text.trim(),
          negocio: _negocioCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Stack(
              children: [
                const AuthHeader(
                  titulo: 'Crea tu\ncuenta',
                  subtitulo: 'Registra tu negocio en minutos',
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 4,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    tooltip: 'Volver',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Error ──
                      Consumer<AuthProvider>(
                        builder: (_, auth, __) {
                          if (auth.errorMessage == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: ErrorBanner(
                              message: auth.errorMessage!,
                              onDismiss: auth.limpiarError,
                            ),
                          );
                        },
                      ),

                      // ─── Datos personales ───────────────────────────────
                      const SectionLabel('Datos personales'),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _nombreCtrl,
                        focusNode: _nombreFocus,
                        label: 'Nombre completo *',
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        onFieldSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_telefonoFocus),
                        validator: Validators.nombre,
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _telefonoCtrl,
                        focusNode: _telefonoFocus,
                        label: 'Teléfono (opcional)',
                        hint: '3XX XXX XXXX',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_negocioFocus),
                        validator: Validators.telefono,
                      ),
                      const SizedBox(height: 24),

                      // ─── Negocio ─────────────────────────────────────────
                      const SectionLabel('Tu negocio'),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _negocioCtrl,
                        focusNode: _negocioFocus,
                        label: 'Nombre del negocio *',
                        prefixIcon: Icons.store_outlined,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_emailFocus),
                        validator: Validators.negocio,
                      ),
                      const SizedBox(height: 24),

                      // ─── Datos de acceso ──────────────────────────────────
                      const SectionLabel('Datos de acceso'),
                      const SizedBox(height: 12),

                      CustomTextField(
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        label: 'Correo electrónico *',
                        hint: 'ejemplo@correo.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newUsername],
                        autocorrect: false,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passFocus),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _passCtrl,
                        focusNode: _passFocus,
                        label: 'Contraseña *',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        onChanged: (val) {
                          setState(() => _passwordActual = val);
                          _confirmFieldKey.currentState?.validate();
                        },
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_confirmFocus),
                        // ✅ Mínimo 8 caracteres (antes 6)
                        validator: Validators.passwordRegistro,
                      ),
                      PasswordStrengthIndicator(password: _passwordActual),
                      const SizedBox(height: 14),

                      CustomTextField(
                        key: _confirmFieldKey,
                        controller: _confirmCtrl,
                        focusNode: _confirmFocus,
                        label: 'Confirmar contraseña *',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onFieldSubmitted: (_) => _registrar(),
                        // ✅ Comparación exacta sin trim()
                        validator: Validators.confirmarPassword(_passCtrl.text),
                      ),
                      const SizedBox(height: 32),

                      Consumer<AuthProvider>(
                        builder: (_, auth, __) => PrimaryButton(
                          text: 'Crear cuenta',
                          isLoading: auth.isLoading,
                          onPressed: _registrar,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                          style: TextStyle(
                            color: AppColors.primario,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
