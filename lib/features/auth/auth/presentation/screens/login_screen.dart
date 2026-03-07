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
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Pantalla de inicio de sesión.
///
/// Flujo: el usuario ingresa credenciales → [AuthProvider.login] →
/// [AuthWrapper] detecta el cambio en el stream y navega al Home.
/// Esta pantalla no navega directamente; delega al wrapper para
/// mantener la separación de responsabilidades.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();

    await context.read<AuthProvider>().login(
          email: _emailCtrl.text.trim(),
          // ✅ Sin trim() en la contraseña — los espacios son parte de ella
          password: _passCtrl.text,
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
            const AuthHeader(
              titulo: 'Bienvenido de\nnuevo',
              subtitulo: 'Inicia sesión para continuar',
              grande: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 28,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Banner de error ──
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

                      // ── Correo ──
                      CustomTextField(
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        label: 'Correo electrónico',
                        hint: 'ejemplo@correo.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passFocus),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),

                      // ── Contraseña ──
                      CustomTextField(
                        controller: _passCtrl,
                        focusNode: _passFocus,
                        label: 'Contraseña',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        validator: Validators.passwordLogin,
                      ),

                      // ── ¿Olvidaste tu contraseña? ──
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 4),
                            minimumSize: const Size(48, 48),
                          ),
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: AppColors.primario,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // ── Botón iniciar sesión ──
                      Consumer<AuthProvider>(
                        builder: (_, auth, __) => PrimaryButton(
                          text: 'Iniciar sesión',
                          isLoading: auth.isLoading,
                          onPressed: _login,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Divisor ──
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: AppColors.borde)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '¿No tienes cuenta?',
                              style: TextStyle(
                                color: AppColors.textoGris,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Expanded(
                              child: Divider(color: AppColors.borde)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Crear cuenta ──
                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primario,
                          side: const BorderSide(color: AppColors.primario),
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Crear cuenta',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
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
