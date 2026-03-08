import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/expense.dart';
import '../../models/expense_category.dart';
import '../../providers/expense_provider.dart';

class RegisterExpenseScreen extends StatefulWidget {
  final Expense? expenseToEdit;

  const RegisterExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<RegisterExpenseScreen> createState() => _RegisterExpenseScreenState();
}

class _RegisterExpenseScreenState extends State<RegisterExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _providerController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  ExpensePaymentType _paymentType = ExpensePaymentType.efectivo;
  ExpenseCategory? _selectedCategory;

  bool _isLoading = false;
  List<ExpenseCategory> _loadedCategories = [];

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  TextEditingController? _activeField;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _nameController.text = e.name ?? '';
      _amountController.text = e.amount.toStringAsFixed(0);
      _providerController.text = e.providerName ?? '';
      _notesController.text = e.notes ?? '';
      _selectedDate = e.date;
      _paymentType = e.paymentType;
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
    );
    await Future.delayed(const Duration(seconds: 4));
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _nameController.dispose();
    _amountController.dispose();
    _providerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addCustomCategoryDialog() {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(
            hintText: 'Nombre de categoría',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
          maxLength: 30,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
            onPressed: () async {
              if (catController.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                await context.read<ExpenseProvider>().addCategory(catController.text.trim());
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Seleccione la fecha del gasto',
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar una categoría')),
      );
      return;
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_amountController.text);
      final prov = context.read<ExpenseProvider>();
      if (widget.expenseToEdit == null) {
        await prov.addExpense(Expense(
          id: '',
          name: _nameController.text.trim(),
          amount: amount,
          date: _selectedDate,
          paymentType: _paymentType,
          providerName: _providerController.text.trim().isEmpty ? null : _providerController.text.trim(),
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          paidAmount: _paymentType == ExpensePaymentType.credito ? 0.0 : amount,
        ));
      } else {
        await prov.editExpense(
          widget.expenseToEdit!,
          amount,
          _nameController.text.trim(),
          _notesController.text.trim(),
          _selectedCategory!,
          _providerController.text.trim().isEmpty ? null : _providerController.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expenseToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Gasto' : 'Registrar Gasto'),
        backgroundColor: const Color(0xFFE11D48),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)))
          : StreamBuilder<List<ExpenseCategory>>(
              stream: context.read<ExpenseProvider>().categoriesStream(),
              builder: (ctx, snap) {
                // Actualizar la lista cargada cada vez que llegan datos
                if (snap.hasData) {
                  _loadedCategories = snap.data!;
                  // Restaurar categoría al editar si aún no está asignada
                  if (isEditing && _selectedCategory == null && _loadedCategories.isNotEmpty) {
                    try {
                      _selectedCategory = _loadedCategories
                          .firstWhere((c) => c.id == widget.expenseToEdit!.categoryId);
                    } catch (_) {}
                  }
                  // Si la categoría seleccionada ya no existe en la lista, resetear
                  if (_selectedCategory != null &&
                      !_loadedCategories.any((c) => c.id == _selectedCategory!.id)) {
                    _selectedCategory = null;
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── NOMBRE DEL GASTO ─────────────────────────────
                        TextFormField(
                          controller: _nameController,
                          maxLength: 150,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Nombre del Gasto *',
                            hintText: 'Ej: Pago de servicios públicos',
                            prefixIcon: const Icon(Icons.label_outline, color: Color(0xFFE11D48)),
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE11D48), width: 2),
                            ),
                            counterText: '',
                            suffixIcon: _speechAvailable
                                ? IconButton(
                                    icon: Icon(
                                      _activeField == _nameController && _isListening
                                          ? Icons.mic
                                          : Icons.mic_none,
                                      color: _activeField == _nameController && _isListening
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onPressed: () => _listen(_nameController),
                                  )
                                : null,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                        ),
                        const SizedBox(height: 14),

                        // ── MONTO ────────────────────────────────────────
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Monto *',
                            prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFE11D48)),
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE11D48), width: 2),
                            ),
                            suffixIcon: _speechAvailable
                                ? IconButton(
                                    icon: Icon(
                                      _activeField == _amountController && _isListening
                                          ? Icons.mic
                                          : Icons.mic_none,
                                      color: _activeField == _amountController && _isListening
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onPressed: () => _listen(_amountController),
                                  )
                                : null,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'El monto es obligatorio';
                            final val = double.tryParse(v);
                            if (val == null) return 'El monto debe ser un número válido';
                            if (val <= 0) return 'El monto debe ser mayor a 0';
                            if (val > 9999999999) return 'El monto excede el límite permitido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── FECHA (fila completa) ─────────────────────────
                        InkWell(
                          onTap: isEditing ? null : _pickDate,
                          borderRadius: BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Fecha del Gasto',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.calendar_today),
                              suffixIcon: isEditing ? null : const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── FORMA DE PAGO (fila completa para evitar overflow) ──
                        DropdownButtonFormField<ExpensePaymentType>(
                          value: _paymentType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Forma de Pago',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payment),
                          ),
                          items: ExpensePaymentType.values.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t.label, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: isEditing
                              ? null
                              : (v) { if (v != null) setState(() => _paymentType = v); },
                        ),
                        const SizedBox(height: 14),

                        // ── CATEGORÍA ─────────────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<ExpenseCategory>(
                                value: _selectedCategory,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Categoría *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                // Fix: Si no hay categorías aún, pasamos lista vacía (no null)
                                items: _loadedCategories.isEmpty
                                    ? null // null desactiva el dropdown limpiamente
                                    : _loadedCategories.map((c) {
                                        return DropdownMenuItem<ExpenseCategory>(
                                          value: c,
                                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                hint: _loadedCategories.isEmpty
                                    ? const Text('Cargando categorías...')
                                    : const Text('Selecciona una categoría'),
                                onChanged: _loadedCategories.isEmpty
                                    ? null
                                    : (v) => setState(() => _selectedCategory = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: const Color(0xFFE11D48).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _addCustomCategoryDialog,
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(Icons.add, color: Color(0xFFE11D48)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── PROVEEDOR ─────────────────────────────────────
                        TextFormField(
                          controller: _providerController,
                          maxLength: 150,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Proveedor (Opcional)',
                            hintText: 'A quién se le paga',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.storefront_outlined),
                            counterText: '',
                            suffixIcon: _speechAvailable
                                ? IconButton(
                                    icon: Icon(
                                      _activeField == _providerController && _isListening
                                          ? Icons.mic
                                          : Icons.mic_none,
                                      color: _activeField == _providerController && _isListening
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onPressed: () => _listen(_providerController),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── NOTAS ─────────────────────────────────────────
                        TextFormField(
                          controller: _notesController,
                          maxLength: 700,
                          maxLines: 4,
                          minLines: 3,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: 'Descripción / Notas (Opcional)',
                            alignLabelWithHint: true,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.description_outlined),
                            ),
                            suffixIcon: _speechAvailable
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 60),
                                    child: IconButton(
                                      icon: Icon(
                                        _activeField == _notesController && _isListening
                                            ? Icons.mic
                                            : Icons.mic_none,
                                        color: _activeField == _notesController && _isListening
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                      onPressed: () => _listen(_notesController),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── BOTÓN GUARDAR ─────────────────────────────────
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isLoading ? null : _save,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(isEditing ? 'GUARDAR CAMBIOS' : 'REGISTRAR GASTO'),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}