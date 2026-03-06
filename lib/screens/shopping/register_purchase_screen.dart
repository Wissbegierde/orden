import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/product.dart';
import '../../models/shopping.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/shopping_provider.dart';

class RegisterPurchaseScreen extends StatefulWidget {
  const RegisterPurchaseScreen({super.key});

  @override
  State<RegisterPurchaseScreen> createState() => _RegisterPurchaseScreenState();
}

class _RegisterPurchaseScreenState extends State<RegisterPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  PaymentType _selectedPaymentType = PaymentType.efectivo;
  DateTime _selectedDate = DateTime.now();
  bool _paid = false;
  Product? _selectedProduct;
  final _quantityCtrl = TextEditingController();

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  TextEditingController? _activeField;

  static const double _maxAmount = 1000000000;
  static const int _maxProviderLength = 100;
  static const int _maxNotesLength = 500;

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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'El monto es obligatorio';
    final normalized = value.replaceAll(' ', '').replaceAll(',', '.');
    final amount = double.tryParse(normalized);
    if (amount == null) return 'El monto debe ser un número válido';
    if (amount <= 0) return 'El monto debe ser mayor a 0';
    if (amount > _maxAmount) return 'El monto supera el límite permitido';
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) return 'La descripción es obligatoria';
    if (value.length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.tryParse(
          _quantityCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (_selectedProduct != null && (qty <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Si seleccionas un producto, ingresa cantidad mayor a 0'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    try {
      final normalizedAmount =
          _amountCtrl.text.replaceAll(' ', '').replaceAll(',', '.');
      final shopping = Shopping(
        description: _descriptionCtrl.text.trim(),
        amount: double.parse(normalizedAmount),
        paymentType: _selectedPaymentType,
        date: _selectedDate,
        paid: _paid,
        providerName: _providerCtrl.text.isEmpty
            ? null
            : _providerCtrl.text.trim(),
        productId: _selectedProduct?.id,
        quantity: _selectedProduct != null && qty > 0 ? qty : null,
      );
      context.read<ShoppingProvider>().addShopping(shopping);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compra registrada exitosamente'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    _providerCtrl.dispose();
    _notesCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Widget _micField({
    required TextEditingController controller,
    required String label,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFF2D51D), width: 2),
        ),
        suffixIcon: _speechAvailable
            ? IconButton(
                icon: Icon(
                  _activeField == controller && _isListening
                      ? Icons.mic
                      : Icons.mic_none,
                  color: _activeField == controller && _isListening
                      ? Colors.red
                      : const Color(0xFFF2D51D),
                ),
                onPressed: () => _listen(controller),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2D51D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Registrar Compra'),
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
                    color: const Color(0xFFF2D51D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          const Color(0xFFF2D51D).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? Colors.red
                            : const Color(0xFFF2D51D),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isListening
                            ? 'Escuchando... habla ahora'
                            : 'Presiona 🎤 en los campos para dictar',
                        style: TextStyle(
                          color: _isListening
                              ? Colors.red
                              : const Color(0xFF92700A),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // Producto (opcional - integra con inventario)
              const Text(
                'Producto (opcional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              StreamBuilder<List<Product>>(
                stream: context.read<InventoryProvider>().stockStream,
                builder: (ctx, snap) {
                  final products = snap.data ?? [];
                  return DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    hint: const Text('Sin producto (solo compra)'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFF2D51D), width: 2),
                      ),
                    ),
                    items: products
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text('${p.name} (Stock: ${p.quantity})'),
                            ))
                        .toList(),
                    onChanged: (p) => setState(() => _selectedProduct = p),
                  );
                },
              ),
              if (_selectedProduct != null) ...[
                const SizedBox(height: 12),
                _micField(
                  controller: _quantityCtrl,
                  label: 'Cantidad a agregar al inventario',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (_selectedProduct == null) return null;
                    final q =
                        int.tryParse(v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
                    if (q == null || q <= 0) return 'Ingresa cantidad > 0';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Descripción
              _micField(
                controller: _descriptionCtrl,
                label: 'Descripción de la Compra',
                validator: _validateDescription,
              ),
              const SizedBox(height: 16),

              // Monto
              _micField(
                controller: _amountCtrl,
                label: 'Monto',
                prefixText: r'$ ',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _validateAmount,
              ),
              const SizedBox(height: 16),

              // Proveedor
              _micField(
                controller: _providerCtrl,
                label: 'Proveedor (Opcional)',
                maxLength: _maxProviderLength,
                validator: (v) {
                  if (v != null && v.length > _maxProviderLength) {
                    return 'Máximo $_maxProviderLength caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Forma de pago
              const Text(
                'Forma de Pago',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<PaymentType>(
                value: _selectedPaymentType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFF2D51D), width: 2),
                  ),
                ),
                items: PaymentType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label),
                      ),
                    )
                    .toList(),
                onChanged: (t) => setState(() => _selectedPaymentType = t!),
              ),
              const SizedBox(height: 16),

              // Estado de pago
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Pagado',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    _paid ? 'Compra ya cancelada' : 'Pendiente de pago',
                    style: TextStyle(
                      fontSize: 12,
                      color: _paid
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                  value: _paid,
                  activeThumbColor: const Color(0xFF10B981),
                  onChanged: (v) => setState(() => _paid = v),
                ),
              ),
              const SizedBox(height: 16),

              // Fecha
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ListTile(
                  title: const Text('Fecha de la Compra'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  trailing: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFFF2D51D),
                  ),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 16),

              // Notas
              _micField(
                controller: _notesCtrl,
                label: 'Notas (Opcional)',
                maxLines: 3,
                maxLength: _maxNotesLength,
                validator: (v) {
                  if (v != null && v.length > _maxNotesLength) {
                    return 'Máximo $_maxNotesLength caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botón registrar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2D51D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _submit,
                  child: const Text(
                    'Registrar Compra',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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