import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../mixins/voice_form_mixin.dart';
import '../../models/bill.dart';
import '../../providers/bills_provider.dart';

class RegisterBillScreen extends StatefulWidget {
  const RegisterBillScreen({super.key});

  @override
  State<RegisterBillScreen> createState() => _RegisterBillScreenState();
}

class _RegisterBillScreenState extends State<RegisterBillScreen>
    with VoiceFormMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _providerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _descriptionFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _providerFocus = FocusNode();
  final _notesFocus = FocusNode();

  BillCategory? _selectedCategory = BillCategory.servicios;
  String? _customCategory;
  bool _useCustomCategory = false;
  PaymentType _selectedPaymentType = PaymentType.efectivo;
  DateTime _selectedDate = DateTime.now();
  bool _paid = false;

  // Constantes de validación
  static const double MAX_AMOUNT = 1000000000;
  static const int MAX_PROVIDER_LENGTH = 100;
  static const int MAX_NOTES_LENGTH = 500;

  @override
  void initState() {
    super.initState();
    initVoiceForm(
      controllers: [_descriptionCtrl, _amountCtrl, _providerCtrl, _notesCtrl],
      focusNodes: [_descriptionFocus, _amountFocus, _providerFocus, _notesFocus],
      isNumeric: [false, true, false, false],
      onSave: _submit,
      accentColor: const Color(0xFFEF4444),
    );
    _amountCtrl.addListener(() => setState(() {}));
    _providerCtrl.addListener(() => setState(() {}));
    _notesCtrl.addListener(() => setState(() {}));
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'El monto es obligatorio';
    final amount = double.tryParse(value);
    if (amount == null) return 'El monto debe ser un número válido';
    if (amount <= 0) return 'El monto debe ser mayor a 0';
    if (amount > MAX_AMOUNT) return 'El monto supera el límite permitido';
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) return 'La descripción es obligatoria';
    if (value.length < 3) return 'La descripción debe tener al menos 3 caracteres';
    return null;
  }

  String? _validateProvider(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length > MAX_PROVIDER_LENGTH) {
        return 'El proveedor no debe exceder $MAX_PROVIDER_LENGTH caracteres';
      }
    }
    return null;
  }

  String? _validateNotes(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length > MAX_NOTES_LENGTH) {
        return 'Las notas no deben exceder $MAX_NOTES_LENGTH caracteres';
      }
    }
    return null;
  }

  void _showCreateCategoryDialog() {
    final categoryCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: categoryCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre de la categoría',
            hintText: 'Ej: Publicidad, Consultoría, etc.',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              final categoryName = categoryCtrl.text.trim();
              if (categoryName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingrese el nombre de la categoría'),
                  ),
                );
                return;
              }
              setState(() {
                _customCategory = categoryName;
                _useCustomCategory = true;
                _selectedCategory = null;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null && _customCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione una categoría')));
      return;
    }

    try {
      final bill = Bill(
        description: _descriptionCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text),
        paymentType: _selectedPaymentType,
        category: _useCustomCategory ? null : _selectedCategory,
        customCategory: _useCustomCategory ? _customCategory : null,
        date: _selectedDate,
        paid: _paid,
        providerName: _providerCtrl.text.isEmpty
            ? null
            : _providerCtrl.text.trim(),
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
      );

      context.read<BillsProvider>().addBill(bill);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gasto registrado exitosamente'),
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
    _descriptionFocus.dispose();
    _amountFocus.dispose();
    _providerFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      floatingActionButton: buildVoiceFAB(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Registrar Gasto'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Voice indicator
                buildVoiceBanner(const Color(0xFFEF4444)),


                // Category selector
                const Text(
                  'Categoría',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...BillCategory.values
                              .map(
                                (cat) => _CategoryChip(
                                  category: cat,
                                  selected:
                                      _selectedCategory == cat &&
                                      !_useCustomCategory,
                                  onTap: () => setState(() {
                                    _selectedCategory = cat;
                                    _useCustomCategory = false;
                                    _customCategory = null;
                                  }),
                                ),
                              )
                              .toList(),
                          const SizedBox(width: 8),
                          InputChip(
                            label: const Text('+ Nueva'),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: _useCustomCategory
                                  ? const Color(0xFFEF4444)
                                  : Colors.grey.shade300,
                            ),
                            labelStyle: TextStyle(
                              color: _useCustomCategory
                                  ? const Color(0xFFEF4444)
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            onPressed: _showCreateCategoryDialog,
                          ),
                        ],
                      ),
                    ),
                    if (_useCustomCategory && _customCategory != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFFEF4444),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Categoría: $_customCategory',
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Description
                TextFormField(
                  controller: _descriptionCtrl,
                  focusNode: _descriptionFocus,
                  decoration: InputDecoration(
                    labelText: 'Descripción del Gasto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: voiceMicIcon(_descriptionCtrl),
                  ),
                  validator: _validateDescription,
                ),
                const SizedBox(height: 16),
                // Amount
                TextFormField(
                  controller: _amountCtrl,
                  focusNode: _amountFocus,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: voiceMicIcon(_amountCtrl),
                  ),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 16),
                // Provider name
                TextFormField(
                  controller: _providerCtrl,
                  focusNode: _providerFocus,
                  maxLength: MAX_PROVIDER_LENGTH,
                  decoration: InputDecoration(
                    labelText: 'Proveedor (Opcional)',
                    helperText:
                        '${_providerCtrl.text.length}/$MAX_PROVIDER_LENGTH caracteres',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: voiceMicIcon(_providerCtrl),
                  ),
                  validator: _validateProvider,
                ),
                const SizedBox(height: 16),
                // Payment type
                const Text(
                  'Forma de Pago',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaymentType>(
                  value: _selectedPaymentType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: PaymentType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (type) =>
                      setState(() => _selectedPaymentType = type!),
                ),
                const SizedBox(height: 16),
                // Date picker
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Fecha'),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                        ),
                        trailing: const Icon(Icons.calendar_today_rounded),
                        onTap: _selectDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Paid checkbox
                CheckboxListTile(
                  title: const Text('Marcar como Pagado'),
                  subtitle: const Text('Selecciona si ya fue pagado'),
                  value: _paid,
                  onChanged: (v) => setState(() => _paid = v ?? false),
                ),
                const SizedBox(height: 16),
                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  focusNode: _notesFocus,
                  maxLength: MAX_NOTES_LENGTH,
                  decoration: InputDecoration(
                    labelText: 'Notas (Opcional)',
                    helperText:
                        '${_notesCtrl.text.length}/$MAX_NOTES_LENGTH caracteres',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: voiceMicIcon(_notesCtrl),
                  ),
                  maxLines: 3,
                  validator: _validateNotes,
                ),
                const SizedBox(height: 24),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'Registrar Gasto',
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
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final BillCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text(category.label),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFEF4444),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? const Color(0xFFEF4444) : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
