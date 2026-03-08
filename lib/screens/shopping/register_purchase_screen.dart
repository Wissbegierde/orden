import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../mixins/voice_form_mixin.dart';
import '../../models/product.dart';
import '../../models/shopping.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/shopping_provider.dart';

class RegisterPurchaseScreen extends StatefulWidget {
  const RegisterPurchaseScreen({super.key});

  @override
  State<RegisterPurchaseScreen> createState() => _RegisterPurchaseScreenState();
}

class _RegisterPurchaseScreenState extends State<RegisterPurchaseScreen>
    with VoiceFormMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();

  final _descriptionFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _providerFocus = FocusNode();
  final _notesFocus = FocusNode();
  final _quantityFocus = FocusNode();

  PaymentType _selectedPaymentType = PaymentType.efectivo;
  DateTime _selectedDate = DateTime.now();
  bool _paid = false;
  Product? _selectedProduct;

  static const double _maxAmount = 1000000000;
  static const int _maxProviderLength = 100;
  static const int _maxNotesLength = 500;

  @override
  void initState() {
    super.initState();
    initVoiceForm(
      controllers: [_descriptionCtrl, _amountCtrl, _providerCtrl, _notesCtrl],
      focusNodes: [_descriptionFocus, _amountFocus, _providerFocus, _notesFocus],
      isNumeric: [false, true, false, false],
      onSave: _submit,
      accentColor: const Color(0xFFF2D51D),
    );
    _quantityCtrl.addListener(_recalcTotal);
  }

  void _recalcTotal() {
    if (_selectedProduct == null || _selectedProduct!.costPrice <= 0) return;
    final qty =
        int.tryParse(_quantityCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (qty > 0) {
      final total = _selectedProduct!.costPrice * qty;
      _amountCtrl.text = total.toStringAsFixed(0);
    }
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
    final qty =
        int.tryParse(_quantityCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (_selectedProduct != null && (qty <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si seleccionas un producto, ingresa cantidad mayor a 0',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    try {
      final normalizedAmount = _amountCtrl.text
          .replaceAll(' ', '')
          .replaceAll(',', '.');
      final shopping = Shopping(
        description: _descriptionCtrl.text.trim(),
        amount: double.parse(normalizedAmount),
        paymentType: _selectedPaymentType,
        date: _selectedDate,
        paid: _paid,
        providerName: _providerCtrl.text.trim(),
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
    disposeVoiceForm();
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    _providerCtrl.dispose();
    _notesCtrl.dispose();
    _quantityCtrl.dispose();
    _descriptionFocus.dispose();
    _amountFocus.dispose();
    _providerFocus.dispose();
    _notesFocus.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  Widget _micField({
    required TextEditingController controller,
    required String label,
    FocusNode? focusNode,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
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
        suffixIcon: voiceMicIcon(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      floatingActionButton: buildVoiceFAB(),
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
              buildVoiceBanner(const Color(0xFFF2D51D)),


              // Producto (opcional - integra con inventario)
              const Text(
                'Producto',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 6),
              StreamBuilder<List<Product>>(
                stream: context.read<InventoryProvider>().stockStream,
                builder: (ctx, snap) {
                  final products = snap.data ?? [];
                  return DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    hint: const Text('Seleccione el producto...'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFF2D51D),
                          width: 2,
                        ),
                      ),
                    ),
                    isExpanded: true,
                    items: products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} (Stock: ${p.quantity})'),
                          ),
                        )
                        .toList(),
                    onChanged: (p) {
                      setState(() => _selectedProduct = p);
                      if (p != null) {
                        _descriptionCtrl.text = p.name;
                        final qty =
                            int.tryParse(
                              _quantityCtrl.text.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              ),
                            ) ??
                            0;
                        if (p.costPrice > 0 && qty > 0) {
                          _amountCtrl.text = (p.costPrice * qty)
                              .toStringAsFixed(0);
                        } else if (p.costPrice > 0) {
                          _amountCtrl.text = p.costPrice.toStringAsFixed(0);
                        }
                      }
                    },
                  );
                },
              ),
              if (_selectedProduct != null) ...[
                const SizedBox(height: 12),
                _micField(
                  controller: _quantityCtrl,
                  focusNode: _quantityFocus,
                  label: 'Cantidad a agregar al inventario',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (_selectedProduct == null) return null;
                    final q = int.tryParse(
                      v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '',
                    );
                    if (q == null || q <= 0) return 'Ingresa cantidad > 0';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Descripción
              _micField(
                controller: _descriptionCtrl,
                focusNode: _descriptionFocus,
                label: 'Descripción de la Compra',
                validator: _validateDescription,
              ),
              const SizedBox(height: 16),

              // Monto
              _micField(
                controller: _amountCtrl,
                focusNode: _amountFocus,
                label: 'Monto',
                prefixText: r'$ ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 16),

              // Proveedor (obligatorio)
              _micField(
                controller: _providerCtrl,
                focusNode: _providerFocus,
                label: 'Proveedor',
                maxLength: _maxProviderLength,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El proveedor es obligatorio';
                  }
                  if (v.length > _maxProviderLength) {
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
                    borderSide: const BorderSide(
                      color: Color(0xFFF2D51D),
                      width: 2,
                    ),
                  ),
                ),
                items: PaymentType.values
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.label)),
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
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                  ),
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
                focusNode: _notesFocus,
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
