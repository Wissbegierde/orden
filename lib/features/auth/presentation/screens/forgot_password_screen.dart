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

/// Pantalla de recuperación de contraseña.
///
/// Flujo:
/// 1. El usuario ingresa su correo y pulsa "Enviar correo".
/// 2. [AuthProvider.recuperarPassword] invoca Firebase.
/// 3. Si el correo es exitoso, se muestra [_mensajeExito] en la misma pantalla.
/// 4. El usuario vuelve al login desde el botón de la pantalla de éxito.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _emailFocus = FocusNode();

  bool _enviado = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();

    final ok = await context
        .read<AuthProvider>()
        .recuperarPassword(_emailCtrl.text.trim());

    if (ok && mounted) {
      HapticFeedback.mediumImpact();
      setState(() => _enviado = true);
    }
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
                  titulo: 'Recuperar\ncontraseña',
                  subtitulo: 'Te enviaremos un correo de recuperación',
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
                  top: 28,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: _enviado ? _mensajeExito() : _formulario(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              if (auth.errorMessage == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ErrorBanner(
                  message: auth.errorMessage!,
                  onDismiss: auth.limpiarError,
                ),
              );
            },
          ),
          const Text(
            'Ingresa el correo de tu cuenta y te enviaremos un enlace para restablecer tu contraseña.',
            style: TextStyle(color: AppColors.textoGris, height: 1.5),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            label: 'Correo electrónico',
            hint: 'ejemplo@correo.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            onFieldSubmitted: (_) => _enviar(),
            validator: Validators.email,
          ),
          const SizedBox(height: 28),
          Consumer<AuthProvider>(
            builder: (_, auth, __) => PrimaryButton(
              text: 'Enviar correo',
              isLoading: auth.isLoading,
              onPressed: _enviar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensajeExito() {
    final email = _emailCtrl.text.trim();
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.exito.withOpacity(0.08),
            border: Border.all(color: AppColors.exito.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.mark_email_read_outlined,
                  color: AppColors.exito, size: 52),
              const SizedBox(height: 16),
              const Text(
                '¡Correo enviado!',
                style: TextStyle(
                  color: AppColors.exito,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Revisa tu bandeja de entrada en $email y sigue las instrucciones para restablecer tu contraseña.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textoGris, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Si no ves el correo, revisa la carpeta de spam.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textoGris,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primario,
              side: const BorderSide(color: AppColors.primario),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Volver al inicio de sesión'),
          ),
        ),
      ],
    );
  }
}
