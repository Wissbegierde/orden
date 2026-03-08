import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_controller.dart';

/// Mixin simplificado que conecta formularios al [VoiceController] global.
///
/// Uso:
/// ```dart
/// class _MyFormState extends State<MyForm> with VoiceFormMixin {
///   @override
///   void initState() {
///     super.initState();
///     initVoiceForm(
///       controllers: [_nameCtrl, _priceCtrl],
///       focusNodes: [_nameFocus, _priceFocus],
///       isNumeric: [false, true],
///       onSave: _save,
///       accentColor: Colors.green,
///     );
///   }
/// }
/// ```
mixin VoiceFormMixin<T extends StatefulWidget> on State<T> {
  // ── getters de conveniencia que leen del VoiceController ───────────────
  VoiceController get _vc => context.read<VoiceController>();

  bool get voiceAvailable => _vc.available;
  bool get voiceListening => _vc.listening;
  TextEditingController? get voiceActiveField => _vc.activeField;
  String get voiceRecognizedText => _vc.lastWords;
  String get voiceFeedbackMessage => _vc.feedback;

  /// Inicializa la voz para el formulario actual.
  void initVoiceForm({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    List<bool>? isNumeric,
    required VoidCallback onSave,
    VoidCallback? onBack,
    Color accentColor = const Color(0xFF10B981),
  }) {
    // Registrar después del primer frame para tener context disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VoiceController>().registerForm(
        controllers: controllers,
        focusNodes: focusNodes,
        isNumeric: isNumeric,
        onSave: onSave,
        onBack: onBack ?? () => Navigator.of(context).pop(),
        color: accentColor,
      );
    });
  }

  /// Activar/desactivar voz manualmente.
  void voiceStartAll() => _vc.toggle();

  /// Toggle desde el icono de un campo individual.
  void voiceListen(TextEditingController controller) => _vc.toggle();

  /// Libera el registro al salir de la pantalla.
  void disposeVoiceForm() {
    // El VoiceController gestiona su propio estado; solo limpiamos el form
    // si el mic no esta activo para no interrumpir al usuario
    if (!_vc.listening) {
      _vc.unregister();
    }
  }

  /// FAB del micrófono para el Scaffold de formularios.
  Widget buildVoiceFAB() {
    return Consumer<VoiceController>(
      builder: (_, vc, __) {
        if (!vc.available) return const SizedBox.shrink();
        return FloatingActionButton(
          heroTag: 'voiceFormFAB_${widget.hashCode}',
          backgroundColor: vc.listening ? Colors.red : vc.accentColor,
          onPressed: vc.toggle,
          tooltip: vc.listening ? 'Desactivar micrófono' : 'Activar micrófono',
          child: Icon(
            vc.listening ? Icons.mic_off : Icons.mic,
            color: Colors.white,
            size: 28,
          ),
        );
      },
    );
  }

  /// Ícono de micrófono para el suffixIcon de un TextFormField.
  Widget? voiceMicIcon(TextEditingController controller) {
    final vc = context.read<VoiceController>();
    if (!vc.available) return null;
    return Consumer<VoiceController>(
      builder: (_, v, __) => IconButton(
        icon: Icon(
          v.listening ? Icons.mic : Icons.mic_none,
          color: v.listening ? Colors.red : Colors.grey,
        ),
        onPressed: v.toggle,
        tooltip: v.listening ? 'Parar' : 'Dictar',
      ),
    );
  }

  /// Banner de estado de voz para mostrar dentro del formulario.
  Widget buildVoiceBanner(Color accentColor) {
    return Consumer<VoiceController>(
      builder: (_, vc, __) {
        if (!vc.available) return const SizedBox.shrink();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    vc.listening ? Icons.mic : Icons.mic_none,
                    color: vc.listening ? Colors.red : accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vc.listening
                          ? 'Escuchando… "Listo" → siguiente campo'
                          : 'Presiona 🎤 para dictar todos los campos',
                      style: TextStyle(
                        color: vc.listening ? Colors.red : accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (vc.listening && vc.lastWords.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🗣 "${vc.lastWords}"',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                ),
              ],
              if (vc.feedback.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  vc.feedback,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: vc.feedback.contains('✅')
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
