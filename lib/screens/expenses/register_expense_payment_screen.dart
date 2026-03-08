import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';

class RegisterExpensePaymentScreen extends StatefulWidget {
  const RegisterExpensePaymentScreen({super.key});

  @override
  State<RegisterExpensePaymentScreen> createState() =>
      _RegisterExpensePaymentScreenState();
}

class _RegisterExpensePaymentScreenState
    extends State<RegisterExpensePaymentScreen> {
  Expense? _selectedExpense;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  TextEditingController? _activeField;

  final _currency =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

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
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = _selectedExpense?.date ?? DateTime(2000);
    final initial =
        _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: firstDate,
      lastDate: now, // TC-PAGO-12: No fechas futuras
      helpText: 'Fecha del abono',
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _registerPayment() async {
    if (_selectedExpense == null || !_formKey.currentState!.validate()) return;
    if (_isLoading) return; // TC-PAGO-15: Evitar doble registro

    setState(() => _isLoading = true);
    try {
      await context.read<ExpenseProvider>().addPayment(
            _selectedExpense!,
            double.parse(_amountController.text),
            _selectedDate,
            _notesController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Pago registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Widget para mostrar la tarjeta de información del gasto seleccionado
  Widget _buildExpenseInfoCard(Expense exp) {
    final totalPaid = exp.paidAmount;
    final pending = exp.pendingAmount;
    final paidPct = exp.amount > 0 ? (totalPaid / exp.amount).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exp.name?.isNotEmpty == true ? exp.name! : exp.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (exp.name?.isNotEmpty == true && exp.categoryName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(exp.categoryName,
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
          const Divider(height: 20),
          // Fila de montos
          Row(
            children: [
              Expanded(child: _InfoCell('Total gasto', _currency.format(exp.amount), Colors.grey.shade700)),
              const SizedBox(width: 8),
              Expanded(child: _InfoCell('Abonado', _currency.format(totalPaid), Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _InfoCell('Pendiente', _currency.format(pending), const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progreso de pago
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: paidPct,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: paidPct >= 1.0 ? Colors.green : const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(paidPct * 100).toStringAsFixed(0)}% pagado',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Fecha del gasto: ${DateFormat('dd/MM/yyyy').format(exp.date)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (exp.providerName?.isNotEmpty == true)
            Text(
              'Proveedor: ${exp.providerName}',
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Registrar Pago de Crédito'),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Expense>>(
        stream: context.read<ExpenseProvider>().expensesStream(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
          }

          final pendingExpenses = (snap.data ?? [])
              .where((e) => e.paymentType == ExpensePaymentType.credito && !e.isPaid)
              .toList();

          // TC-PAGO-02: Sin gastos pendientes
          if (pendingExpenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        size: 64, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No hay gastos pendientes de pago',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '¡Estás al día con tus pagos!',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // TC-PAGO-16: Si el gasto seleccionado ya no existe en la lista actualizada, resetear
          if (_selectedExpense != null &&
              !pendingExpenses.any((e) => e.id == _selectedExpense!.id)) {
            _selectedExpense = null;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SELECTOR DE GASTO
                  const Text(
                    'Selecciona el gasto a pagar',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E1B4B)),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Expense>(
                    value: _selectedExpense,
                    isExpanded: true,
                    itemHeight: 56, // Altura suficiente para 2 líneas de texto
                    decoration: const InputDecoration(
                      labelText: 'Gasto con crédito pendiente',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt_long, color: Color(0xFFF59E0B)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF59E0B), width: 2),
                      ),
                    ),
                    hint: const Text('Selecciona un gasto...'),
                    items: pendingExpenses.map((e) {
                      final displayName = e.name?.isNotEmpty == true
                          ? e.name!
                          : e.categoryName;
                      final pendingStr = NumberFormat.currency(
                        locale: 'es_CO', symbol: '\$', decimalDigits: 0,
                      ).format(e.pendingAmount);
                      return DropdownMenuItem<Expense>(
                        value: e,
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            text: displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: '  —  Pendiente: $pendingStr',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedExpense = v;
                        _amountController.clear();
                        if (v != null) {
                          final now = DateTime.now();
                          // Fecha de abono no puede ser antes del gasto
                          if (_selectedDate.isBefore(v.date)) {
                            _selectedDate = now;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // TARJETA INFORMATIVA DEL GASTO SELECCIONADO
                  if (_selectedExpense != null) ...[
                    _buildExpenseInfoCard(_selectedExpense!),
                    const SizedBox(height: 20),

                    // MONTO A ABONAR
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Monto a Abonar *',
                        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFF59E0B)),
                        border: const OutlineInputBorder(),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFF59E0B), width: 2),
                        ),
                        helperText:
                            'Máximo: ${_currency.format(_selectedExpense!.pendingAmount)}',
                        helperStyle: const TextStyle(color: Color(0xFFF59E0B)),
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
                        if (v == null || v.isEmpty) return 'El monto es obligatorio'; // TC-PAGO-04
                        final val = double.tryParse(v);
                        if (val == null) return 'El monto debe ser un número válido'; // TC-PAGO-05
                        if (val <= 0) return 'El monto debe ser mayor a 0'; // TC-PAGO-06/07
                        if (val > _selectedExpense!.pendingAmount) {
                          return 'El monto supera el valor pendiente (${_currency.format(_selectedExpense!.pendingAmount)})'; // TC-PAGO-08
                        }
                        if (val > 9999999999) return 'Monto excedido'; // TC-PAGO-18
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // FECHA DEL ABONO
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha del Abono',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // NOTAS
                    TextFormField(
                      controller: _notesController,
                      maxLength: 500,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: 'Notas del Abono (Opcional)',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.notes),
                        ),
                        suffixIcon: _speechAvailable
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 40),
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

                    // BOTÓN REGISTRAR PAGO
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isLoading ? null : _registerPayment,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('REGISTRAR PAGO'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Widget auxiliar para celdas de información
class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoCell(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: valueColor),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}