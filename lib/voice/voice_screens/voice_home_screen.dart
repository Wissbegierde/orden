// lib/voice/voice_screens/voice_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../voice_service.dart';
import '../voice_controller.dart';

class VoiceHomeScreen extends StatefulWidget {
  const VoiceHomeScreen({super.key});

  @override
  State<VoiceHomeScreen> createState() => _VoiceHomeScreenState();
}

class _VoiceHomeScreenState extends State<VoiceHomeScreen> {
  late VoiceService _voiceService;
  late VoiceController _controller;

  @override
  void initState() {
    super.initState();
    _voiceService = context.read<VoiceService>();
    _controller = VoiceController(
      context: context,
      voiceService: _voiceService,
    );

    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _voiceService.initialize();
    await _voiceService.speak(
      'Bienvenido. Puedes decir: ir a gastos, registrar ingreso, o ver inventario',
    );
  }

  void _startListening() {
    _voiceService.startListening((text) {
      _controller.processCommand(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Título
            const Text(
              'Control por Voz',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
            ),

            const SizedBox(height: 20),

            // Indicador de escucha
            Consumer<VoiceService>(
              builder: (context, service, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: service.isListening ? 200 : 150,
                  height: service.isListening ? 200 : 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: service.isListening
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF8B5CF6),
                    boxShadow: service.isListening
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    service.isListening ? Icons.mic : Icons.mic_none,
                    size: 80,
                    color: Colors.white,
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Texto reconocido
            Consumer<VoiceService>(
              builder: (context, service, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    service.lastWords.isEmpty
                        ? 'Presiona el micrófono y di un comando'
                        : service.lastWords,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                );
              },
            ),

            const Spacer(),

            // Botón de micrófono
            Consumer<VoiceService>(
              builder: (context, service, child) {
                return GestureDetector(
                  onTap: service.isListening
                      ? () => service.stopListening()
                      : _startListening,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: service.isListening
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : [
                                const Color(0xFF8B5CF6),
                                const Color(0xFF7C3AED),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (service.isListening
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF8B5CF6))
                                  .withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      service.isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Ejemplos de comandos
            const Text(
              'Ejemplos de comandos:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '"Registrar gasto de 50 mil en transporte"\n'
              '"Ver gastos de hoy"\n'
              '"Ir a inventario"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
