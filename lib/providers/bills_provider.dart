import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/bill.dart';

class BillsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // ── Gastos ────────────────────────────────────────────────────
  Stream<List<Bill>> billsStream() {
    return _db
        .collection('gastos')
        .where('deletedAt', isNull: true) // Solo gastos no eliminados
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Bill.fromFirestore).toList());
  }

  Stream<List<Bill>> billsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _db
        .collection('gastos')
        .where('deletedAt', isNull: true) // Solo gastos no eliminados
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Bill.fromFirestore).toList());
  }

  Stream<List<Bill>> billsByCategory(BillCategory category) {
    return _db
        .collection('gastos')
        .where('deletedAt', isNull: true) // Solo gastos no eliminados
        .where('category', isEqualTo: category.name)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Bill.fromFirestore).toList());
  }

  Stream<List<Bill>> unpaidBills() {
    return _db
        .collection('gastos')
        .where('deletedAt', isNull: true) // Solo gastos no eliminados
        .where('paid', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Bill.fromFirestore).toList());
  }

  // Stream para gastos eliminados (para auditoría)
  Stream<List<Bill>> deletedBillsStream() {
    return _db
        .collection('gastos')
        .where('deletedAt', isNull: false) // Solo gastos eliminados
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Bill.fromFirestore).toList());
  }

  Future<void> addBill(Bill bill) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.collection('gastos').add(bill.toFirestore());
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateBill(String billId, Bill bill) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.collection('gastos').doc(billId).update(bill.toFirestore());
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Soft delete - marca el gasto como eliminado con motivo
  Future<void> softDeleteBill(
    String billId,
    String reason,
    String deletedBy,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.collection('gastos').doc(billId).update({
        'deletedAt': Timestamp.fromDate(DateTime.now()),
        'deletedReason': reason,
        'deletedBy': deletedBy,
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Método obsoleto - mantener por compatibilidad pero no usar
  Future<void> deleteBill(String billId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.collection('gastos').doc(billId).delete();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Pagos de Gastos ────────────────────────────────────────────
  Stream<List<BillPayment>> paymentsStream() {
    return _db
        .collection('pagos_gastos')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BillPayment.fromFirestore).toList());
  }

  Stream<List<BillPayment>> paymentsForBill(String billId) {
    return _db
        .collection('pagos_gastos')
        .where('billId', isEqualTo: billId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(BillPayment.fromFirestore).toList());
  }

  Future<void> addPayment(BillPayment payment) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _db.collection('pagos_gastos').add(payment.toFirestore());
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Reportes ──────────────────────────────────────────────────
  Future<List<Bill>> fetchBillsForRange(DateTime from, DateTime to) async {
    final snap = await _db
        .collection('gastos')
        .where('deletedAt', isNull: true) // Solo gastos no eliminados
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date')
        .get();
    return snap.docs.map(Bill.fromFirestore).toList();
  }

  Future<List<BillPayment>> fetchPaymentsForRange(
    DateTime from,
    DateTime to,
  ) async {
    final snap = await _db
        .collection('pagos_gastos')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date')
        .get();
    return snap.docs.map(BillPayment.fromFirestore).toList();
  }

  Future<double> getTotalBillsForRange(DateTime from, DateTime to) async {
    final bills = await fetchBillsForRange(from, to);
    return bills.fold<double>(0.0, (sum, bill) => sum + bill.amount);
  }

  Future<double> getTotalPaymentsForRange(DateTime from, DateTime to) async {
    final payments = await fetchPaymentsForRange(from, to);
    return payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
  }
}
