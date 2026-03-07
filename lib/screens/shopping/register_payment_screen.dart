import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/shopping.dart';
import '../../providers/shopping_provider.dart';

class RegisterPaymentScreen extends StatefulWidget {
  const RegisterPaymentScreen({super.key});

  @override
  State<RegisterPaymentScreen> createState() => _RegisterPaymentScreenState();
}

class _RegisterPaymentScreenState extends State<RegisterPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Shopping? _selectedShopping;
  String? _selectedShoppingId;
  double _selectedBalance = 0;
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedShopping == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una compra')),
      );
      return;
    }

    final normalizedAmount =
        _amountCtrl.text.replaceAll(' ', '').replaceAll(',', '.');
    final amount = double.tryParse(normalizedAmount);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un monto válido mayor a 0')),
      );
      return;
    }
    if (amount > 1000000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto demasiado grande')),
      );
      return;
    }
    if (amount > _selectedBalance && _selectedBalance > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El monto no puede superar el saldo pendiente (${NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0).format(_selectedBalance)})',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final payment = ShoppingPayment(
      shoppingId: _selectedShopping!.id!,
      amount: amount,
      date: _selectedDate,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );

    context.read<ShoppingProvider>().addPayment(payment);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pago a proveedor registrado'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Widget _buildBillsDropdown() {
    return StreamBuilder<List<PurchaseWithBalance>>(
      stream: context.read<ShoppingProvider>().unpaidShoppingsWithBalance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF2D51D)),
          );
        }
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Error cargando compras',
              style: TextStyle(color: Colors.red.shade800),
            ),
          );
        }

        final items = snapshot.data ?? [];

        PurchaseWithBalance? currentSelection;
        if (_selectedShoppingId != null) {
          try {
            currentSelection =
                items.firstWhere((x) => x.shopping.id == _selectedShoppingId);
          } catch (_) {
            _selectedShoppingId = null;
            _selectedShopping = null;
          }
        }

        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2D51D).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'No hay compras pendientes de pago',
              style: TextStyle(color: Color(0xFF92700A)),
            ),
          );
        }

        final currency = NumberFormat.currency(
          locale: 'es_CO',
          symbol: r'$',
          decimalDigits: 0,
        );

        if (currentSelection != null &&
            _selectedBalance != currentSelection.balance) {
          final balance = currentSelection.balance;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedBalance = balance);
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<PurchaseWithBalance>(
          value: currentSelection,
          isExpanded: true,
          hint: const Text('Seleccione proveedor'),
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFFF2D51D), width: 2),
            ),
          ),
          items: items.map((item) {
            final providerName =
                item.shopping.providerName?.trim().isNotEmpty == true
                    ? item.shopping.providerName!.trim()
                    : 'Sin proveedor';
            return DropdownMenuItem<PurchaseWithBalance>(
              value: item,
              child: Text(
                '$providerName — ${currency.format(item.balance)} pendiente',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (item) {
            setState(() {
              if (item != null) {
                _selectedShopping = item.shopping;
                _selectedShoppingId = item.shopping.id;
                _selectedBalance = item.balance;
              }
            });
          },
        ),
            _billDetails(currentSelection?.balance ?? _selectedBalance),
          ],
        );
      },
    );
  }

  Widget _billDetails(double? balance) {
    if (_selectedShopping == null) return const SizedBox();
    final s = _selectedShopping!;
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    );
    final saldoPendiente = balance ?? _selectedBalance;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2D51D).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF2D51D).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Monto Total', currency.format(s.amount)),
          const SizedBox(height: 4),
          _detailRow(
            'Saldo pendiente',
            currency.format(saldoPendiente),
            isHighlight: true,
          ),
          const SizedBox(height: 4),
          _detailRow('Fecha', DateFormat('dd/MM/yyyy').format(s.date)),
          if (s.providerName?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            _detailRow('Proveedor', s.providerName!),
          ],
          const SizedBox(height: 4),
          if (s.productId == null)
            _detailRow('Lo comprado', s.description)
          else
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('productos')
                  .doc(s.productId!)
                  .get(),
              builder: (context, snapshot) {
                String value = s.description;
                if (snapshot.hasData && snapshot.data!.data() != null) {
                  final data = snapshot.data!.data()!;
                  final name = (data['name'] as String?)?.trim();
                  if (name != null && name.isNotEmpty) {
                    // Solo mostramos el nombre del producto
                    value = name;
                  }
                }
                return _detailRow('Lo comprado', value);
              },
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isHighlight ? const Color(0xFFF59E0B) : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Registrar Pago a Proveedor'),
        backgroundColor: const Color(0xFFF2D51D),
        foregroundColor: Colors.white,
        elevation: 0,
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
                    color: const Color(0xFFF2D51D).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          const Color(0xFFF2D51D).withValues(alpha: 0.4),
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
              const Text(
                'Seleccionar Compra',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 10),
              _buildBillsDropdown(),
              const SizedBox(height: 20),
              const Text(
                'Monto del Pago',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: r'$ ',
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
                  suffixIcon: _speechAvailable
                      ? IconButton(
                          icon: Icon(
                            _activeField == _amountCtrl && _isListening
                                ? Icons.mic
                                : Icons.mic_none,
                            color: _activeField == _amountCtrl && _isListening
                                ? Colors.red
                                : const Color(0xFFF2D51D),
                          ),
                          onPressed: () => _listen(_amountCtrl),
                        )
                      : null,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingrese el monto';
                  final normalized =
                      v.replaceAll(' ', '').replaceAll(',', '.');
                  final val = double.tryParse(normalized);
                  if (val == null) return 'Número inválido';
                  if (val <= 0) return 'Debe ser mayor a 0';
                  if (val > 1000000000) return 'Monto demasiado grande';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha del Pago'),
                subtitle:
                    Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFFF2D51D),
                ),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFF2D51D),
                      width: 2,
                    ),
                  ),
                  suffixIcon: _speechAvailable
                      ? IconButton(
                          icon: Icon(
                            _activeField == _notesCtrl && _isListening
                                ? Icons.mic
                                : Icons.mic_none,
                            color: _activeField == _notesCtrl && _isListening
                                ? Colors.red
                                : const Color(0xFFF2D51D),
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
                    backgroundColor: const Color(0xFFF2D51D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Registrar Pago',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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