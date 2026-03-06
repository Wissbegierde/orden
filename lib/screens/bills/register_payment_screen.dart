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
  String? _selectedBillId; // ✅ Guardamos solo el ID

  DateTime _selectedDate = DateTime.now();

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

    try {
      await _speech.listen(
        onResult: (result) {
          field.text = result.recognizedWords;
          setState(() {});
        },
      );
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

    final amount = double.tryParse(_amountCtrl.text);

    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser un número válido')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a 0')),
      );
      return;
    }

    if (amount > 1000000000) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Monto demasiado grande')));
      return;
    }

    final payment = BillPayment(
      billId: _selectedBill!.id!,
      amount: amount,
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

  Widget _buildBillsDropdown() {
    return StreamBuilder<List<Bill>>(
      stream: context.read<BillsProvider>().unpaidBills(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Error cargando gastos',
              style: TextStyle(color: Colors.red.shade800),
            ),
          );
        }

        final bills = snapshot.data ?? [];

        // ✅ SOLUCIÓN MEJORADA: Sincronizar _selectedBill con la lista actual
        Bill? currentSelection = _selectedBill;
        if (_selectedBillId != null) {
          // Buscar el bill por ID en la lista actual
          try {
            currentSelection = bills.firstWhere((b) => b.id == _selectedBillId);
          } catch (e) {
            // Si no se encuentra, limpiamos la selección
            currentSelection = null;
            _selectedBillId = null;
          }
        }

        if (bills.isEmpty) {
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
          value: currentSelection,
          hint: const Text('Seleccione un gasto'),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: bills.map((bill) {
            return DropdownMenuItem(
              value: bill,
              child: Text(
                '${bill.description} - ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(bill.amount)}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (bill) {
            setState(() {
              _selectedBill = bill;
              _selectedBillId = bill?.id; // ✅ Guardamos el ID
            });
          },
        );
      },
    );
  }

  Widget _billDetails() {
    if (_selectedBill == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monto Total'),
              Text(
                NumberFormat.currency(
                  locale: 'es_CO',
                  symbol: '\$',
                  decimalDigits: 0,
                ).format(_selectedBill!.amount),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Categoría'),
              Text(_selectedBill!.categoryLabel),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fecha'),
              Text(DateFormat('dd/MM/yyyy').format(_selectedBill!.date)),
            ],
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
        title: const Text('Registrar Pago de Gasto'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seleccionar Gasto',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              _buildBillsDropdown(),

              _billDetails(),

              const SizedBox(height: 20),

              const Text(
                'Monto del Pago',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

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
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Ingrese el monto';
                  }

                  final value = double.tryParse(v);

                  if (value == null) {
                    return 'El monto debe ser un número válido';
                  }

                  if (value <= 0) {
                    return 'Debe ser mayor a 0';
                  }

                  if (value > 1000000000) {
                    return 'Monto demasiado grande';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              ListTile(
                title: const Text('Fecha del Pago'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
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
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Registrar Pago',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
