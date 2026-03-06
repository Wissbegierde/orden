// lib/voice/voice_service.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _isInitialized = false;
  String _lastWords = '';

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;

  Future<bool> initialize() async {
    // Solicitar permisos de micrófono
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    // Inicializar speech to text
    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('Error de voz: $error'),
      onStatus: (status) => debugPrint('Estado: $status'),
    );

    // Configurar TTS (español)
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.5); // Velocidad normal
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    notifyListeners();
    return _isInitialized;
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isListening) return;

    _isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;

        if (result.finalResult) {
          onResult(_lastWords);
          stopListening();
        }

        notifyListeners();
      },
      localeId: 'es_ES', // Español
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}
