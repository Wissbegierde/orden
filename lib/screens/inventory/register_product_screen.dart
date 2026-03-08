import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/income_sale.dart';
import '../../models/product.dart';
import '../../providers/inventory_provider.dart';

class RegisterProductScreen extends StatefulWidget {
  final Product? productToEdit;
  const RegisterProductScreen({super.key, this.productToEdit});

  @override
  State<RegisterProductScreen> createState() => _RegisterProductScreenState();
}

class _RegisterProductScreenState extends State<RegisterProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();

  PaymentType _selectedType = PaymentType.efectivo;

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  TextEditingController? _activeField;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      _nameCtrl.text = p.name;
      _priceCtrl.text = p.price.toStringAsFixed(0);
      _quantityCtrl.text = p.quantity.toString();
      _selectedType = PaymentTypeExtension.fromString(p.defaultPayment);
    }
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
        field.text = result.recognizedWords;
      },
      onSoundLevelChange: (_) {},
    );
    await Future.delayed(const Duration(seconds: 4));
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final price =
        double.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;
    final quantity =
        int.tryParse(_quantityCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final product = Product(
      id: widget.productToEdit?.id ?? 'new',
      name: name,
      price: price,
      quantity: quantity,
      defaultPayment: _selectedType.name,
    );

    await context.read<InventoryProvider>().addOrUpdateProduct(product);

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _speech.stop();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info general
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ingresa la información inicial del producto para añadirlo al inventario.',
                        style: TextStyle(
                          color: Color(0xFF1E1B4B),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _SectionLabel(text: 'Nombre del Producto *'),
              _VoiceField(
                controller: _nameCtrl,
                hint: 'Ej: Café Volcán 500g',
                keyboardType: TextInputType.text,
                isListening: _isListening && _activeField == _nameCtrl,
                onMic: _speechAvailable ? () => _listen(_nameCtrl) : null,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              _SectionLabel(text: 'Precio de Venta *'),
              _VoiceField(
                controller: _priceCtrl,
                hint: 'Ej: 25000',
                keyboardType: TextInputType.number,
                isListening: _isListening && _activeField == _priceCtrl,
                onMic: _speechAvailable ? () => _listen(_priceCtrl) : null,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _SectionLabel(text: 'Cantidad en Stock *'),
              _VoiceField(
                controller: _quantityCtrl,
                hint: 'Ej: 10',
                keyboardType: TextInputType.number,
                isListening: _isListening && _activeField == _quantityCtrl,
                onMic: _speechAvailable ? () => _listen(_quantityCtrl) : null,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (int.tryParse(v) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _SectionLabel(text: 'Método de pago predeterminado *'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentType.values.map((type) {
                  final selected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: selected,
                    selectedColor: const Color(0xFF3B82F6),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              Consumer<InventoryProvider>(
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
                            'Guardar Producto',
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
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
  }
}

class _VoiceField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool isListening;
  final VoidCallback? onMic;
  final String? Function(String?)? validator;

  const _VoiceField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.isListening,
    this.onMic,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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