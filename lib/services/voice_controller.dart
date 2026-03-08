import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'voice_command_service.dart';

/// Controlador global de voz. Se registra como Provider en el árbol de Widgets.
///
/// Opera en dos modos:
/// - [FormMode]: llena campos de un formulario campo por campo.
/// - [NavigationMode]: procesa comandos de navegación en pantallas de módulo.
///
/// Solo existe UNA instancia activa de SpeechToText para toda la app.
class VoiceController extends ChangeNotifier {
  final _speech = SpeechToText();

  // ──── Estado público ────────────────────────────────────────────────────
  bool available = false;
  bool listening = false;
  String lastWords = '';
  String feedback = '';
  Color accentColor = const Color(0xFF4F46E5);

  TextEditingController? get activeField {
    if (!_inFormMode || _controllers.isEmpty || _currentIdx >= _controllers.length) return null;
    return _controllers[_currentIdx];
  }

  // ──── Modo formulario ───────────────────────────────────────────────────
  List<TextEditingController> _controllers = [];
  List<FocusNode> _focusNodes = [];
  List<bool> _isNumeric = [];
  int _currentIdx = 0;
  VoidCallback? _onSave;
  VoidCallback? _onBack;
  bool _inFormMode = false;
  bool _commandProcessing = false;
  String _preListenValue = '';
  final Map<int, String> _savedValues = {};

  // ──── Modo navegación ───────────────────────────────────────────────────
  bool Function(String)? _navigationHandler;

  // ──── Inicialización ────────────────────────────────────────────────────
  Future<void> init() async {
    if (available) return;
    available = await _speech.initialize(
      onError: (e) => _onError(),
      onStatus: (s) => _onStatus(s),
    );
    notifyListeners();
  }

  void _onError() {
    // Si hay error, intentar reiniciar
    if (listening) {
      Future.delayed(const Duration(seconds: 1), _restartListening);
    }
  }

  void _onStatus(String status) {
    // Cuando el motor se detiene (timeout), reiniciar automáticamente
    if (status == 'done' && listening && !_commandProcessing) {
      Future.delayed(const Duration(milliseconds: 300), _restartListening);
    }
    if (status == 'notListening' && listening && !_commandProcessing) {
      Future.delayed(const Duration(milliseconds: 300), _restartListening);
    }
  }

  // ──── Registro de modo ──────────────────────────────────────────────────

  /// Registra los campos de un formulario. Llama en initState.
  void registerForm({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    List<bool>? isNumeric,
    required VoidCallback onSave,
    VoidCallback? onBack,
    Color color = const Color(0xFF4F46E5),
  }) {
    _controllers = controllers;
    _focusNodes = focusNodes;
    _isNumeric = isNumeric ?? List.filled(controllers.length, false);
    _onSave = onSave;
    _onBack = onBack;
    _inFormMode = true;
    accentColor = color;
    _commandProcessing = false;
    _savedValues.clear();
    _currentIdx = 0;
    notifyListeners();
  }

  /// Registra el handler de navegación de una pantalla de módulo.
  void registerNavigation({
    required bool Function(String normalized) onCommand,
    Color color = const Color(0xFF4F46E5),
  }) {
    _navigationHandler = onCommand;
    _inFormMode = false;
    accentColor = color;
    notifyListeners();
  }

  /// Limpia el modo activo. Llama en dispose de cada pantalla.
  void unregister() {
    if (listening) {
      _speech.stop();
      listening = false;
    }
    _navigationHandler = null;
    _inFormMode = false;
    _controllers = [];
    _focusNodes = [];
    _isNumeric = [];
    _onSave = null;
    _onBack = null;
    lastWords = '';
    feedback = '';
    notifyListeners();
  }

  // ──── Control de escucha ────────────────────────────────────────────────

  /// Activa o desactiva el micrófono.
  Future<void> toggle() async {
    if (!available) return;
    if (listening) {
      await _speech.stop();
      listening = false;
      lastWords = '';
      feedback = '';
      notifyListeners();
    } else {
      if (_inFormMode && _controllers.isNotEmpty) {
        _currentIdx = 0;
        _commandProcessing = false;
        _savedValues.clear();
        _preListenValue = _controllers[0].text;
        _focusNodes[_currentIdx].requestFocus();
        feedback = '🎤 Campo 1 de ${_controllers.length}';
      } else {
        feedback = '🎤 Escuchando...';
      }
      listening = true;
      lastWords = '';
      notifyListeners();
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!listening || _speech.isListening) return;
    final capturedIdx = _currentIdx;

    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        if (words.isEmpty) return;

        lastWords = words;
        notifyListeners();

        if (_commandProcessing || (_inFormMode && capturedIdx != _currentIdx)) return;

        if (_inFormMode) {
          _handleFormResult(words, result.finalResult, capturedIdx);
        } else {
          _handleNavResult(words, result.finalResult);
        }
      },
      localeId: 'es_CO',
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  Future<void> _restartListening() async {
    if (!listening || _commandProcessing || _speech.isListening) return;
    await Future.delayed(const Duration(milliseconds: 200));
    if (!listening || _commandProcessing) return;
    await _startListening();
  }

  // ──── Lógica formulario ─────────────────────────────────────────────────

  void _handleFormResult(String words, bool isFinal, int capturedIdx) {
    if (!isFinal) {
      // Mostrar texto parcial en el campo actual sin confirmarlo
      return;
    }

    final normalized = VoiceCommandService.normalize(words);

    // ── Comando: Guardar ──
    if (VoiceCommandService.matchesAny(normalized, VoiceCommandService.guardarAliases)) {
      _commandProcessing = true;
      // Restaurar valor previo (no escribir "guardar")
      if (capturedIdx < _controllers.length) {
        _controllers[capturedIdx].text = _preListenValue;
      }
      feedback = '💾 Guardando...';
      notifyListeners();
      _speech.stop();
      listening = false;
      Future.microtask(() => _onSave?.call());
      return;
    }

    // ── Comando: Volver ──
    if (VoiceCommandService.matchesAny(normalized, VoiceCommandService.volverAliases)) {
      _commandProcessing = true;
      if (capturedIdx < _controllers.length) {
        _controllers[capturedIdx].text = _preListenValue;
      }
      feedback = '↩️ Volviendo...';
      notifyListeners();
      _speech.stop();
      listening = false;
      Future.microtask(() => _onBack?.call());
      return;
    }

    // ── Comando: Listo / Siguiente ──
    if (VoiceCommandService.matchesAny(normalized, VoiceCommandService.listoAliases)) {
      _commandProcessing = true;
      // Conservar el valor que había antes de escuchar (no escribir "listo")
      if (capturedIdx < _controllers.length) {
        _controllers[capturedIdx].text = _preListenValue;
        _savedValues[capturedIdx] = _preListenValue;
      }
      _speech.stop();
      _advanceToNextField();
      return;
    }

    // ── Llenar campo ──
    if (capturedIdx < _controllers.length) {
      String textToSet = words;
      if (capturedIdx < _isNumeric.length && _isNumeric[capturedIdx]) {
        textToSet = VoiceCommandService.extractNumber(words);
      }
      _controllers[capturedIdx].text = textToSet;
      _controllers[capturedIdx].selection = TextSelection.fromPosition(
        TextPosition(offset: textToSet.length),
      );
      feedback = '';
      notifyListeners();
      // Guardar como valor confirmado y reiniciar escucha
      _preListenValue = textToSet;
      Future.delayed(const Duration(milliseconds: 300), _restartListening);
    }
  }

  void _advanceToNextField() {
    final nextIdx = _currentIdx + 1;
    if (nextIdx < _controllers.length) {
      _currentIdx = nextIdx;
      _preListenValue = _controllers[nextIdx].text;
      _focusNodes[nextIdx].requestFocus();
      feedback = '✅ Campo ${nextIdx + 1} de ${_controllers.length}';
      notifyListeners();
      // Reiniciar escucha en el nuevo campo
      Future.delayed(const Duration(milliseconds: 500), () {
        _commandProcessing = false;
        // Restaurar valores guardados por si algo los sobreescribió
        for (final e in _savedValues.entries) {
          if (e.key < _controllers.length &&
              _controllers[e.key].text != e.value) {
            _controllers[e.key].text = e.value;
          }
        }
        _restartListening();
      });
    } else {
      // Último campo: esperar "guardar"
      feedback = '📋 Último campo. Diga "Guardar"';
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 500), () {
        _commandProcessing = false;
        _restartListening();
      });
    }
  }

  // ──── Lógica navegación ─────────────────────────────────────────────────

  void _handleNavResult(String words, bool isFinal) {
    if (!isFinal) return;
    final normalized = VoiceCommandService.normalize(words);
    final matched = _navigationHandler?.call(normalized) ?? false;
    if (!matched && words.isNotEmpty) {
      feedback = '🤔 No entiendo: "$words"';
      notifyListeners();
      Future.delayed(const Duration(seconds: 3), () {
        if (feedback.contains('No entiendo')) {
          feedback = '🎤 Escuchando...';
          notifyListeners();
        }
      });
    }
    Future.delayed(const Duration(milliseconds: 300), _restartListening);
  }

  // ──── Helper para formularios: ir a campo específico por índice ──────────
  void goToField(int index) {
    if (index < 0 || index >= _controllers.length) return;
    _currentIdx = index;
    _preListenValue = _controllers[index].text;
    _focusNodes[index].requestFocus();
    feedback = '🎤 Campo ${index + 1} de ${_controllers.length}';
    notifyListeners();
  }
}
