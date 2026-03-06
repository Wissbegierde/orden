import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/income_payment.dart';
import '../../providers/income_provider.dart';

class RegisterPaymentScreen extends StatefulWidget {
  const RegisterPaymentScreen({super.key});

  @override
  State<RegisterPaymentScreen> createState() => _RegisterPaymentScreenState();
}

class _RegisterPaymentScreenState extends State<RegisterPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  TextEditingController? _activeField;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  Future<void> _listen(TextEditingController field) async {
    if (!_speechAvailable) return;
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() {
      _isListening = true;
      _activeField = field;
    });
    await _speech.listen(
      onResult: (result) {
        setState(() {
          field.text = result.recognizedWords;
          field.selection = TextSelection.fromPosition(
            TextPosition(offset: field.text.length),
          );
        });
      },
      localeId: 'es_CO',
    );
    Future.delayed(const Duration(seconds: 5), () {
      if (_isListening) {
        _speech.stop();
        setState(() => _isListening = false);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final payment = IncomePayment(
      clientName: _clientCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
      date: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await context.read<IncomeProvider>().addPayment(payment);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _clientCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Registrar Abono'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_speechAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? Colors.red
                            : const Color(0xFF3B82F6),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isListening
                            ? 'Escuchando... habla ahora'
                            : 'Presiona 🎤 para dictar',
                        style: TextStyle(
                          color: _isListening
                              ? Colors.red
                              : const Color(0xFF3B82F6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              _label('Cliente *'),
              _voiceField(
                controller: _clientCtrl,
                hint: 'Nombre del cliente',
                isListening: _isListening && _activeField == _clientCtrl,
                onMic: _speechAvailable ? () => _listen(_clientCtrl) : null,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Ingresa el nombre del cliente'
                    : null,
              ),
              const SizedBox(height: 16),

              _label('Monto del abono *'),
              _voiceField(
                controller: _amountCtrl,
                hint: 'Ej: 20000',
                keyboardType: TextInputType.number,
                isListening: _isListening && _activeField == _amountCtrl,
                onMic: _speechAvailable ? () => _listen(_amountCtrl) : null,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el monto';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _label('Notas (opcional)'),
              _voiceField(
                controller: _notesCtrl,
                hint: 'Detalles del abono',
                maxLines: 3,
                isListening: _isListening && _activeField == _notesCtrl,
                onMic: _speechAvailable ? () => _listen(_notesCtrl) : null,
              ),
              const SizedBox(height: 30),

              Consumer<IncomeProvider>(
                builder: (ctx, provider, _) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: provider.loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: provider.loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Guardar Abono',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E1B4B),
        fontSize: 14,
      ),
    ),
  );

  Widget _voiceField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isListening = false,
    VoidCallback? onMic,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        suffixIcon: onMic != null
            ? IconButton(
                icon: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? Colors.red : Colors.grey,
                ),
                onPressed: onMic,
              )
            : null,
      ),
    );
  }
}
