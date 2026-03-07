import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/income_sale.dart';
import '../models/income_payment.dart';
import '../models/product.dart';

class IncomeProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // ── Productos ──────────────────────────────────────────────────
  Stream<List<Product>> productsStream() {
    return _db
        .collection('productos')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Product.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  // ── Ventas ────────────────────────────────────────────────────
  Stream<List<IncomeSale>> salesStream() {
    return _db
        .collection('ventas')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IncomeSale.fromFirestore).toList());
  }

  Stream<List<IncomeSale>> salesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection('ventas')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IncomeSale.fromFirestore).toList());
  }

  Future<void> addSale(IncomeSale sale) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (sale.productId != null && sale.quantity != null) {
        // Transacción para descontar stock y crear venta en lote seguro
        final productRef = _db.collection('productos').doc(sale.productId);
        final saleRef = _db.collection('ventas').doc();

        await _db.runTransaction((transaction) async {
          final pDoc = await transaction.get(productRef);
          if (!pDoc.exists) {
            throw Exception("Producto no encontrado");
          }
          final currentQty = (pDoc.data()?['quantity'] as num?)?.toInt() ?? 0;
          if (currentQty < sale.quantity!) {
            throw Exception("Stock insuficiente (Actual: \$currentQty)");
          }

          transaction.update(productRef, {
            'quantity': currentQty - sale.quantity!,
          });
          transaction.set(saleRef, sale.toFirestore());
        });
      } else {
        // Venta libre (sin producto asociado)
        await _db.collection('ventas').add(sale.toFirestore());
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Abonos ────────────────────────────────────────────────────
  Stream<List<IncomePayment>> paymentsStream() {
    return _db
        .collection('abonos')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IncomePayment.fromFirestore).toList());
  }

  Stream<List<IncomePayment>> paymentsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection('abonos')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IncomePayment.fromFirestore).toList());
  }

  Future<void> addPayment(IncomePayment payment) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.collection('abonos').add(payment.toFirestore());
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Deudas de crédito ─────────────────────────────────────────
  // Returns all credit sales that still have a pending balance
  Stream<List<IncomeSale>> creditDebtsStream() {
    return _db
        .collection('ventas')
        .where('paymentType', isEqualTo: 'credito')
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map(IncomeSale.fromFirestore)
                  .where((s) => (s.pendingAmount ?? 0) > 0)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date)),
        );
  }

  // Apply a payment against a credit sale, reducing its pendingAmount
  Future<void> applyPaymentToSale(String saleId, double paymentAmount) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final saleRef = _db.collection('ventas').doc(saleId);
      await _db.runTransaction((tx) async {
        final doc = await tx.get(saleRef);
        if (!doc.exists) throw Exception('Venta no encontrada');
        final current =
            (doc.data()?['pendingAmount'] as num?)?.toDouble() ?? 0.0;
        final newPending = (current - paymentAmount).clamp(
          0.0,
          double.infinity,
        );
        tx.update(saleRef, {'pendingAmount': newPending});
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cleanOldCreditSales() async {
    try {
      final snap = await _db
          .collection('ventas')
          .where('paymentType', isEqualTo: 'credito')
          .get();
      int count = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final clientName = data['clientName'] as String?;
        if (clientName != 'Pedro Aponte') {
          await doc.reference.delete();
          count++;
        }
      }
      print('=== DELETED $count OLD CREDIT SALES ===');
    } catch (e) {
      print('Error cleaning: $e');
    }
  }

  // ── Reportes ──────────────────────────────────────────────────
  Future<List<IncomeSale>> fetchSalesForRange(
    DateTime from,
    DateTime to,
  ) async {
    final snap = await _db
        .collection('ventas')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date')
        .get();
    return snap.docs.map(IncomeSale.fromFirestore).toList();
  }

  Future<List<IncomePayment>> fetchPaymentsForRange(
    DateTime from,
    DateTime to,
  ) async {
    final snap = await _db
        .collection('abonos')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date')
        .get();
    return snap.docs.map(IncomePayment.fromFirestore).toList();
  }
}
