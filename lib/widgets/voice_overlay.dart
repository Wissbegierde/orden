import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_controller.dart';

/// Overlay que envuelve pantallas de MÓDULO (no formularios).
/// Muestra un FAB de micrófono + banner superior con texto reconocido.
///
/// Uso:
/// ```dart
/// VoiceCommandOverlay(
///   accentColor: Color(0xFF10B981),
///   onCommand: (normalized) => _handleVoice(normalized),  // retorna bool
///   child: MyScreenBody(),
/// )
/// ```
class VoiceCommandOverlay extends StatefulWidget {
  final Widget child;
  final Color accentColor;
  final bool Function(String normalizedText) onCommand;

  const VoiceCommandOverlay({
    super.key,
    required this.child,
    required this.accentColor,
    required this.onCommand,
  });

  @override
  State<VoiceCommandOverlay> createState() => _VoiceCommandOverlayState();
}

class _VoiceCommandOverlayState extends State<VoiceCommandOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Registrar esta pantalla en el VoiceController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VoiceController>().registerNavigation(
        onCommand: widget.onCommand,
        color: widget.accentColor,
      );
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    // No llamamos unregister aquí para no interrumpir al usuario si navega
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceController>(
      builder: (_, vc, __) {
        // Sincronizar animación de pulso
        if (vc.listening && !_pulseCtrl.isAnimating) {
          _pulseCtrl.repeat(reverse: true);
        } else if (!vc.listening && _pulseCtrl.isAnimating) {
          _pulseCtrl.stop();
          _pulseCtrl.reset();
        }

        return Stack(
          children: [
            widget.child,

            // ── Banner superior (visible solo al escuchar) ──
            if (vc.listening)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: _TopBanner(vc: vc, accentColor: widget.accentColor),
              ),

            // ── FAB micrófono ──
            Positioned(
              right: 16,
              bottom: 16,
              child: ScaleTransition(
                scale: vc.listening
                    ? _pulseAnim
                    : const AlwaysStoppedAnimation(1.0),
                child: FloatingActionButton(
                  heroTag: 'voiceOverlayFAB_${widget.hashCode}',
                  backgroundColor:
                      vc.listening ? Colors.red : widget.accentColor,
                  onPressed: vc.toggle,
                  tooltip:
                      vc.listening ? 'Desactivar micrófono' : 'Activar micrófono',
                  child: Icon(
                    vc.listening ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBanner extends StatelessWidget {
  final VoiceController vc;
  final Color accentColor;
  const _TopBanner({required this.vc, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          accentColor.withValues(alpha: 0.96),
          accentColor.withValues(alpha: 0.82),
        ]),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vc.lastWords.isEmpty
                        ? 'Escuchando… diga un comando'
                        : '🗣 "${vc.lastWords}"',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: vc.toggle,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            if (vc.feedback.isNotEmpty && vc.feedback.contains('No entiendo')) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vc.feedback,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
