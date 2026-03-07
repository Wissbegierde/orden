import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

/// Pantalla de verificación de correo electrónico.
///
/// **Mejoras respecto a la versión anterior:**
/// - **Backoff exponencial**: los intervalos de sondeo aumentan progresivamente
///   (5 s → 10 s → 20 s → 30 s → 30 s…) en lugar de un timer fijo cada 5 s.
/// - **Límite de intentos**: se detiene automáticamente después de 20 intentos
///   (~7 minutos) para no generar tráfico innecesario a Firebase.
/// - **Contador de tiempo restante**: muestra al usuario cuándo se volverá
///   a comprobar, mejorando la UX sin polling constante.
///
/// Flujo:
/// 1. El usuario recibe el correo de verificación al registrarse.
/// 2. Esta pantalla sondea periódicamente si el correo fue verificado.
/// 3. Cuando Firebase lo confirma, [AuthWrapper] navega al Home.
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

  int _intentos = 0;
  static const int _maxIntentos = 20;
  int _segundosHastaSiguiente = 5;

  // Contador regresivo de UI
  Timer? _countdownTimer;
  int _countdownSeconds = 5;

  @override
  void initState() {
    super.initState();
    _programarSiguienteChequeo();
  }

  /// Backoff exponencial: 5 s, 10 s, 20 s, 30 s, 30 s…
  Duration get _intervaloDeSondeo {
    final segundos = min(5 * pow(2, _intentos).toInt(), 30);
    return Duration(seconds: segundos);
  }

  void _programarSiguienteChequeo() {
    if (_intentos >= _maxIntentos) return;

    final intervalo = _intervaloDeSondeo;
    _segundosHastaSiguiente = intervalo.inSeconds;
    _countdownSeconds = _segundosHastaSiguiente;

    // Timer principal: comprueba la verificación
    _checkTimer?.cancel();
    _checkTimer = Timer(intervalo, () async {
      if (!mounted) return;
      _intentos++;
      await context.read<AuthProvider>().recargarUsuario();
      if (mounted) _programarSiguienteChequeo();
    });

    // Timer de cuenta regresiva: actualiza el contador en la UI cada segundo
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _countdownSeconds = (_countdownSeconds - 1).clamp(0, _segundosHastaSiguiente);
      });
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _reenviarCorreo() async {
    if (_enviandoReenvio) return;
    setState(() {
      _enviandoReenvio = true;
      _reenvioExitoso = false;
    });

    final ok = await context.read<AuthProvider>().enviarVerificacionEmail();

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
    final agotado = _intentos >= _maxIntentos;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Ícono ──
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primario.withValues(alpha: 0.1),
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

                      const SizedBox(height: 28),

                      // ── Indicador de estado ──
                      if (!agotado)
                        _IndicadorEspera(
                          segundos: _countdownSeconds,
                          intentos: _intentos,
                          maxIntentos: _maxIntentos,
                        )
                      else
                        _AvisoAgotado(onReintentar: () {
                          setState(() => _intentos = 0);
                          _programarSiguienteChequeo();
                        }),

                      // ── Reenvío exitoso ──
                      if (_reenvioExitoso) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.exito.withValues(alpha: 0.08),
                            border: Border.all(
                                color: AppColors.exito.withValues(alpha: 0.3)),
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
                                style:
                                    TextStyle(color: AppColors.exito, fontSize: 13),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _IndicadorEspera extends StatelessWidget {
  final int segundos;
  final int intentos;
  final int maxIntentos;

  const _IndicadorEspera({
    required this.segundos,
    required this.intentos,
    required this.maxIntentos,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primario,
            value: segundos > 0 ? null : 0,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          segundos > 0
              ? 'Verificando en $segundos s…'
              : 'Verificando…',
          style: TextStyle(
            color: AppColors.textoGris.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($intentos/$maxIntentos)',
          style: TextStyle(
            color: AppColors.textoGris.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _AvisoAgotado extends StatelessWidget {
  final VoidCallback onReintentar;

  const _AvisoAgotado({required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'La verificación automática se pausó.\nPulsa el botón para intentar de nuevo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textoGris, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onReintentar,
          child: const Text(
            'Reanudar verificación automática',
            style: TextStyle(color: AppColors.primario, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
