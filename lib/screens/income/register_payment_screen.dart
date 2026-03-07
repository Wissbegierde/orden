import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/income_payment.dart';
import '../../models/income_sale.dart';
import '../../providers/income_provider.dart';

class RegisterPaymentScreen extends StatefulWidget {
  const RegisterPaymentScreen({super.key});

  @override
  State<RegisterPaymentScreen> createState() => _RegisterPaymentScreenState();
}

class _RegisterPaymentScreenState extends State<RegisterPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Selected debtor from the search dropdown
  IncomeSale? _selectedDebt;

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

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
    setState(() => _isListening = true);
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
    if (_selectedDebt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el cliente deudor')),
      );
      return;
    }

    final paymentAmount = double.parse(
      _amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );

    final provider = context.read<IncomeProvider>();

    // Save the abono record
    final payment = IncomePayment(
      clientName: _selectedDebt!.clientName ?? '',
      amount: paymentAmount,
      date: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await provider.addPayment(payment);

    // Apply the abono against the pending sale balance
    if (_selectedDebt!.id != null) {
      await provider.applyPaymentToSale(_selectedDebt!.id!, paymentAmount);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

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
              const SizedBox(height: 8),

              // ── Buscador de clientes deudores ─────────────────────────
              _label('Cliente deudor *'),
              StreamBuilder<List<IncomeSale>>(
                stream: context.read<IncomeProvider>().creditDebtsStream(),
                builder: (ctx, snapshot) {
                  final debts = snapshot.data ?? [];

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      debts.isEmpty) {
                    return const LinearProgressIndicator();
                  }

                  if (debts.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No hay clientes con deudas pendientes.',
                              style: TextStyle(
                                color: Color(0xFF1E1B4B),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu<IncomeSale>(
                        width: constraints.maxWidth,
                        menuHeight: 260,
                        hintText: 'Busca cliente por nombre...',
                        initialSelection: _selectedDebt,
                        inputDecorationTheme: InputDecorationTheme(
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
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownMenuEntries: debts.map((debt) {
                          return DropdownMenuEntry<IncomeSale>(
                            value: debt,
                            label:
                                '${debt.clientName ?? 'Sin nombre'} — Debe: ${currency.format(debt.pendingAmount ?? 0)}',
                          );
                        }).toList(),
                        onSelected: (debt) {
                          setState(() => _selectedDebt = debt);
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Deuda pendiente resumen
              if (_selectedDebt != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDebt!.clientName ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1B4B),
                            ),
                          ),
                          Text(
                            'Saldo pendiente: ${currency.format(_selectedDebt!.pendingAmount ?? 0)}',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ── Monto del abono ───────────────────────────────────────
              _label('Monto del abono *'),
              _voiceField(
                controller: _amountCtrl,
                hint: 'Ej: 20000',
                keyboardType: TextInputType.number,
                isListening: _isListening,
                onMic: _speechAvailable ? () => _listen(_amountCtrl) : null,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el monto';
                  final parsed = double.tryParse(
                    v.replaceAll(RegExp(r'[^0-9.]'), ''),
                  );
                  if (parsed == null || parsed <= 0) return 'Monto inválido';
                  if (_selectedDebt != null &&
                      parsed > (_selectedDebt!.pendingAmount ?? 0)) {
                    return 'Supera la deuda pendiente (${currency.format(_selectedDebt!.pendingAmount ?? 0)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Notas ─────────────────────────────────────────────────
              _label('Notas (opcional)'),
              _voiceField(
                controller: _notesCtrl,
                hint: 'Detalles del abono',
                maxLines: 3,
                isListening: false,
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
