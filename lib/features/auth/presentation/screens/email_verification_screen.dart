import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

/// Pantalla de verificación de correo electrónico.
///
/// Se muestra después del registro (o si se detecta que el email no está verificado).
/// Cada 5 segundos recarga el estado de Firebase para detectar automáticamente
/// si el usuario verificó su correo en otro tab o dispositivo.
///
/// Flujo:
/// 1. El usuario recibe el correo de verificación automáticamente al registrarse.
/// 2. Esta pantalla les pide que confirmen antes de continuar.
/// 3. Cuando Firebase detecta la verificación, [AuthWrapper] navega al Home.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _checkTimer;
  bool _enviandoReenvio = false;
  bool _reenvioExitoso = false;

  @override
  void initState() {
    super.initState();
    _iniciarVerificacionPeriodica();
  }

  /// Recarga el usuario cada 5 s para detectar la verificación sin que el
  /// usuario tenga que pulsar "ya verifiqué".
  void _iniciarVerificacionPeriodica() {
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      await context.read<AuthProvider>().recargarUsuario();
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _reenviarCorreo() async {
    if (_enviandoReenvio) return;
    setState(() {
      _enviandoReenvio = true;
      _reenvioExitoso = false;
    });

    final ok =
        await context.read<AuthProvider>().enviarVerificacionEmail();

    if (mounted) {
      setState(() {
        _enviandoReenvio = false;
        _reenvioExitoso = ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.usuario?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              // ── Ilustración ──
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primario.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 52,
                          color: AppColors.primario,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Verifica tu correo',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textoOscuro,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enviamos un enlace de verificación a\n$email',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textoGris,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Abre el correo y pulsa el enlace para activar tu cuenta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textoGris,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),

                      // ── Indicador de espera automática ──
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primario,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Esperando verificación…',
                            style: TextStyle(
                              color: AppColors.textoGris.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      // ── Mensaje reenvío exitoso ──
                      if (_reenvioExitoso) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.exito.withOpacity(0.08),
                            border: Border.all(
                                color: AppColors.exito.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  color: AppColors.exito, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Correo reenviado correctamente',
                                style: TextStyle(
                                    color: AppColors.exito, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Acciones ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    text: 'Reenviar correo de verificación',
                    isLoading: _enviandoReenvio,
                    onPressed: _reenviarCorreo,
                    color: AppColors.secundario,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: auth.isLoading ? null : () => auth.logout(),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: AppColors.textoGris),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
