import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../mixins/voice_form_mixin.dart';
import '../../models/income_sale.dart';
import '../../models/product.dart';
import '../../providers/income_provider.dart';

class RegisterSaleScreen extends StatefulWidget {
  const RegisterSaleScreen({super.key});

  @override
  State<RegisterSaleScreen> createState() => _RegisterSaleScreenState();
}

class _RegisterSaleScreenState extends State<RegisterSaleScreen>
    with VoiceFormMixin {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _initialPaymentCtrl = TextEditingController();

  final _qtyFocus = FocusNode();
  final _clientFocus = FocusNode();
  final _notesFocus = FocusNode();

  Product? _selectedProduct;
  PaymentType _selectedType = PaymentType.efectivo;
  bool _hasInitialPayment = false;

  @override
  void initState() {
    super.initState();
    initVoiceForm(
      controllers: [_qtyCtrl, _clientCtrl, _notesCtrl],
      focusNodes: [_qtyFocus, _clientFocus, _notesFocus],
      isNumeric: [true, false, false],
      onSave: _save,
      accentColor: const Color(0xFF10B981),
    );
    _qtyCtrl.addListener(() => setState(() {}));
  }

  double get _currentTotal {
    if (_selectedProduct == null) return 0;
    final qty =
        int.tryParse(_qtyCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return _selectedProduct!.price * qty;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un producto')),
      );
      return;
    }

    final qty = int.parse(_qtyCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (qty > _selectedProduct!.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock insuficiente. Disponible: ${_selectedProduct!.quantity}',
          ),
        ),
      );
      return;
    }

    double? initialPayment;
    double? pendingAmount;
    if (_selectedType == PaymentType.credito) {
      if (_hasInitialPayment && _initialPaymentCtrl.text.isNotEmpty) {
        initialPayment = double.tryParse(
          _initialPaymentCtrl.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        );
      }
      pendingAmount = _currentTotal - (initialPayment ?? 0.0);
    }

    final sale = IncomeSale(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      quantity: qty,
      amount: _currentTotal,
      paymentType: _selectedType,
      clientName: _clientCtrl.text.trim().isEmpty
          ? null
          : _clientCtrl.text.trim(),
      initialPayment: initialPayment,
      pendingAmount: pendingAmount,
      date: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    await context.read<IncomeProvider>().addSale(sale);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    disposeVoiceForm();
    _qtyCtrl.dispose();
    _clientCtrl.dispose();
    _notesCtrl.dispose();
    _initialPaymentCtrl.dispose();
    _qtyFocus.dispose();
    _clientFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curFmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      floatingActionButton: buildVoiceFAB(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Registrar Venta'),
      ),
      body: StreamBuilder<List<Product>>(
        stream: context.read<IncomeProvider>().productsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _selectedProduct == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildVoiceBanner(const Color(0xFF10B981)),

                  // Producto

                  _SectionLabel(text: 'Producto *'),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu<Product>(
                        width: constraints.maxWidth,
                        menuHeight: 300,
                        initialSelection: _selectedProduct,
                        hintText: 'Selecciona o busca un producto...',
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
                              color: Color(0xFF10B981),
                              width: 2,
                            ),
                          ),
                        ),
                        dropdownMenuEntries: products.map((p) {
                          return DropdownMenuEntry<Product>(
                            value: p,
                            label: '${p.name} (Disp: ${p.quantity})',
                          );
                        }).toList(),
                        onSelected: (p) {
                          if (p != null) {
                            setState(() {
                              _selectedProduct = p;
                              _selectedType = PaymentTypeExtension.fromString(
                                p.defaultPayment,
                              );
                            });
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Precio Unitario (Solo Lectura)
                  _SectionLabel(text: 'Precio Unitario'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedProduct != null
                          ? curFmt.format(_selectedProduct!.price)
                          : '\$0',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cantidad
                  _SectionLabel(text: 'Cantidad *'),
                  _VoiceField(
                    controller: _qtyCtrl,
                    focusNode: _qtyFocus,
                    hint: 'Ej: 2',
                    keyboardType: TextInputType.number,
                    isListening: voiceListening && voiceActiveField == _qtyCtrl,
                    onMic: voiceAvailable ? () => voiceListen(_qtyCtrl) : null,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Ingresa la cantidad';
                      }
                      final q = int.tryParse(
                        v.replaceAll(RegExp(r'[^0-9]'), ''),
                      );
                      if (q == null || q <= 0) {
                        return 'Cantidad inválida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Total a pagar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total a cobrar',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          curFmt.format(_currentTotal),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tipo de pago
                  _SectionLabel(text: 'Método de pago *'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PaymentType.values.map((type) {
                      final selected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type.label),
                        selected: selected,
                        selectedColor: const Color(0xFF10B981),
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF1E1B4B),
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _selectedType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // --- Bloque condicional: Crédito ---
                  if (_selectedType == PaymentType.credito) ...[
                    // Cliente obligatorio en crédito
                    _SectionLabel(text: 'Cliente *'),
                    _VoiceField(
                      controller: _clientCtrl,
                      focusNode: _clientFocus,
                      hint: 'Nombre del cliente (requerido en crédito)',
                      isListening: voiceListening && voiceActiveField == _clientCtrl,
                      onMic: voiceAvailable
                          ? () => voiceListen(_clientCtrl)
                          : null,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Requerido en crédito'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Switch: ¿Abono inicial?
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '¿El cliente hace un abono inicial?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E1B4B),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _hasInitialPayment,
                                activeColor: Colors.orange,
                                onChanged: (v) =>
                                    setState(() => _hasInitialPayment = v),
                              ),
                            ],
                          ),
                          if (_hasInitialPayment) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _initialPaymentCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Monto del abono inicial',
                                prefixText: '\$ ',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE5E7EB),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.orange,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (!_hasInitialPayment) return null;
                                if (v == null || v.isEmpty) {
                                  return 'Ingresa el monto del abono';
                                }
                                final parsed = double.tryParse(
                                  v.replaceAll(RegExp(r'[^0-9.]'), ''),
                                );
                                if (parsed == null || parsed <= 0) {
                                  return 'Monto inválido';
                                }
                                if (parsed > _currentTotal) {
                                  return 'No puede superar el total';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Cliente opcional en contado/nequi
                    _SectionLabel(text: 'Cliente (opcional)'),
                    _VoiceField(
                      controller: _clientCtrl,
                      focusNode: _clientFocus,
                      hint: 'Nombre del cliente',
                      isListening: voiceListening && voiceActiveField == _clientCtrl,
                      onMic: voiceAvailable
                          ? () => voiceListen(_clientCtrl)
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notas
                  _SectionLabel(text: 'Notas (opcional)'),
                  _VoiceField(
                    controller: _notesCtrl,
                    focusNode: _notesFocus,
                    hint: 'Detalles adicionales',
                    maxLines: 2,
                    isListening: voiceListening && voiceActiveField == _notesCtrl,
                    onMic: voiceAvailable ? () => voiceListen(_notesCtrl) : null,
                  ),
                  const SizedBox(height: 30),

                  // Botón Guardar
                  Consumer<IncomeProvider>(
                    builder: (ctx, provider, _) => SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: provider.loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: provider.loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Guardar Venta',
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
          );
        },
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
  final FocusNode? focusNode;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final bool isListening;
  final VoidCallback? onMic;
  final FormFieldValidator<String>? validator;

  const _VoiceField({
    required this.controller,
    required this.hint,
    this.focusNode,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.isListening = false,
    this.onMic,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
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
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
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
