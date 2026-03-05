import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/bill.dart';
import '../../providers/bills_provider.dart';

class RegisterBillPaymentScreen extends StatefulWidget {
  const RegisterBillPaymentScreen({super.key});

  @override
  State<RegisterBillPaymentScreen> createState() =>
      _RegisterBillPaymentScreenState();
}

class _RegisterBillPaymentScreenState extends State<RegisterBillPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Bill? _selectedBill;
  DateTime _selectedDate = DateTime.now();

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  TextEditingController? _activeField;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _amountCtrl.addListener(() => setState(() {}));
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
    try {
      final result = await _speech.listen(
        onResult: (result) {
          field.text = result.recognizedWords;
          setState(() {});
        },
      );
      if (!result) {
        setState(() => _isListening = false);
      }
    } catch (e) {
      setState(() => _isListening = false);
    }
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBill == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione un gasto')));
      return;
    }
    if (_amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingrese el monto')));
      return;
    }

    final payment = BillPayment(
      billId: _selectedBill!.id!,
      amount: double.parse(_amountCtrl.text),
      date: _selectedDate,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );

    context.read<BillsProvider>().addPayment(payment);
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pago registrado')));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Registrar Pago de Gasto'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Select bill
                const Text(
                  'Seleccionar Gasto',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Bill>>(
                  stream: context.read<BillsProvider>().unpaidBills(),
                  builder: (ctx, snap) {
                    final unpaidBills = snap.data ?? [];
                    if (unpaidBills.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'No hay gastos pendientes de pago',
                          style: TextStyle(color: Color(0xFF1E40AF)),
                        ),
                      );
                    }
                    return DropdownButtonFormField<Bill>(
                      value: _selectedBill,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      hint: const Text('Seleccione un gasto'),
                      items: unpaidBills
                          .map(
                            (bill) => DropdownMenuItem(
                              value: bill,
                              child: Text(
                                '${bill.description} - \$${NumberFormat('#,###', 'es_CO').format(bill.amount)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (bill) => setState(() => _selectedBill = bill),
                    );
                  },
                ),
                if (_selectedBill != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalle del Gasto',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monto Total:'),
                            Text(
                              NumberFormat.currency(
                                locale: 'es_CO',
                                symbol: '\$',
                                decimalDigits: 0,
                              ).format(_selectedBill!.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Categoría:'),
                            Text(_selectedBill!.categoryLabel),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Fecha:'),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(_selectedBill!.date),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Amount
                const Text(
                  'Monto del Pago',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: _speechAvailable
                        ? IconButton(
                            icon: Icon(
                              _activeField == _amountCtrl && _isListening
                                  ? Icons.mic
                                  : Icons.mic_none,
                              color: const Color(0xFF8B5CF6),
                            ),
                            onPressed: () => _listen(_amountCtrl),
                          )
                        : null,
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                // Date picker
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Fecha del Pago'),
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
                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Notas (Opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: _speechAvailable
                        ? IconButton(
                            icon: Icon(
                              _activeField == _notesCtrl && _isListening
                                  ? Icons.mic
                                  : Icons.mic_none,
                              color: const Color(0xFF8B5CF6),
                            ),
                            onPressed: () => _listen(_notesCtrl),
                          )
                        : null,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'Registrar Pago',
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
