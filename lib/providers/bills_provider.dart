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
    return _db.collection('gastos').snapshots().map((snap) {
      final bills = snap.docs.map(Bill.fromFirestore).toList();

      final activeBills = bills.where((bill) => !bill.isDeleted).toList();

      // ordenar en memoria
      activeBills.sort((a, b) => b.date.compareTo(a.date));

      return activeBills;
    });
  }

  Stream<List<Bill>> billsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return _db
        .collection('gastos')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
          final bills = snap.docs.map(Bill.fromFirestore).toList();

          final activeBills = bills.where((bill) => !bill.isDeleted).toList();

          activeBills.sort((a, b) => b.date.compareTo(a.date));

          return activeBills;
        });
  }

  Stream<List<Bill>> billsByCategory(BillCategory category) {
    return _db
        .collection('gastos')
        .where('category', isEqualTo: category.name)
        .snapshots()
        .map((snap) {
          final bills = snap.docs.map(Bill.fromFirestore).toList();

          final activeBills = bills.where((bill) => !bill.isDeleted).toList();

          activeBills.sort((a, b) => b.date.compareTo(a.date));

          return activeBills;
        });
  }

  Stream<List<Bill>> unpaidBills() {
    return _db
        .collection('gastos')
        .where('paid', isEqualTo: false)
        .snapshots()
        .map((snap) {
          final bills = snap.docs.map(Bill.fromFirestore).toList();

          final activeBills = bills.where((bill) => !bill.isDeleted).toList();

          activeBills.sort((a, b) => b.date.compareTo(a.date));

          return activeBills;
        });
  }

  // ── Gastos eliminados (auditoría) ─────────────────────────────

  Stream<List<Bill>> deletedBillsStream() {
    return _db.collection('gastos').snapshots().map((snap) {
      final bills = snap.docs.map(Bill.fromFirestore).toList();

      final deletedBills = bills.where((bill) => bill.isDeleted).toList();

      deletedBills.sort(
        (a, b) => (b.deletedAt ?? DateTime(2000)).compareTo(
          a.deletedAt ?? DateTime(2000),
        ),
      );

      return deletedBills;
    });
  }

  // ── CRUD Gastos ───────────────────────────────────────────────

  Future<void> addBill(Bill bill) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Crear el gasto
      final docRef = await _db.collection('gastos').add(bill.toFirestore());

      // ✅ Si el gasto está marcado como pagado, crear automáticamente un registro de pago
      if (bill.paid) {
        final payment = BillPayment(
          billId: docRef.id,
          amount: bill.amount,
          date: bill.date,
          notes: 'Pago automático al registrar gasto',
        );
        await _db.collection('pagos_gastos').add(payment.toFirestore());
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
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
    }

    _loading = false;
    notifyListeners();
  }

  // ── Soft Delete ───────────────────────────────────────────────

  Future<void> softDeleteBill(
    String billId,
    String reason,
    String deletedBy,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final paymentsSnap = await _db
          .collection('pagos_gastos')
          .where('billId', isEqualTo: billId)
          .limit(1)
          .get();

      if (paymentsSnap.docs.isNotEmpty) {
        throw Exception(
          'No se puede eliminar este gasto porque tiene pagos registrados.',
        );
      }

      await _db.collection('gastos').doc(billId).update({
        'deletedAt': Timestamp.fromDate(DateTime.now()),
        'deletedReason': reason,
        'deletedBy': deletedBy,
      });
    } catch (e) {
      _error = e.toString();
      rethrow;
    }

    _loading = false;
    notifyListeners();
  }

  // método antiguo
  Future<void> deleteBill(String billId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.collection('gastos').doc(billId).delete();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  // ── Pagos de Gastos ───────────────────────────────────────────

  Stream<List<BillPayment>> paymentsStream() {
    return _db.collection('pagos_gastos').snapshots().map((snap) {
      final payments = snap.docs.map(BillPayment.fromFirestore).toList();

      payments.sort((a, b) => b.date.compareTo(a.date));

      return payments;
    });
  }

  Stream<List<BillPayment>> paymentsForBill(String billId) {
    return _db
        .collection('pagos_gastos')
        .where('billId', isEqualTo: billId)
        .snapshots()
        .map((snap) {
          final payments = snap.docs.map(BillPayment.fromFirestore).toList();

          payments.sort((a, b) => b.date.compareTo(a.date));

          return payments;
        });
  }

  Future<void> addPayment(BillPayment payment) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Añadir el pago
      await _db.collection('pagos_gastos').add(payment.toFirestore());

      // ✅ Verificar si el gasto ya está completamente pagado
      final billDoc = await _db.collection('gastos').doc(payment.billId).get();
      if (!billDoc.exists) {
        throw Exception('El gasto no existe');
      }

      final bill = Bill.fromFirestore(billDoc);

      // Obtener todos los pagos de este gasto
      final paymentsSnap = await _db
          .collection('pagos_gastos')
          .where('billId', isEqualTo: payment.billId)
          .get();

      final totalPaid = paymentsSnap.docs
          .map(BillPayment.fromFirestore)
          .fold<double>(0.0, (total, p) => total + p.amount);

      // Si el total pagado >= monto del gasto, marcarlo como pagado
      if (totalPaid >= bill.amount && !bill.paid) {
        await _db.collection('gastos').doc(payment.billId).update({
          'paid': true,
        });
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Reportes ──────────────────────────────────────────────────

  Future<List<Bill>> fetchBillsForRange(DateTime from, DateTime to) async {
    final snap = await _db
        .collection('gastos')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .get();

    final bills = snap.docs.map(Bill.fromFirestore).toList();

    final activeBills = bills.where((bill) => !bill.isDeleted).toList();

    activeBills.sort((a, b) => b.date.compareTo(a.date));

    return activeBills;
  }

  Future<List<BillPayment>> fetchPaymentsForRange(
    DateTime from,
    DateTime to,
  ) async {
    final snap = await _db
        .collection('pagos_gastos')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .get();

    final payments = snap.docs.map(BillPayment.fromFirestore).toList();

    payments.sort((a, b) => b.date.compareTo(a.date));

    return payments;
  }

  Future<double> getTotalBillsForRange(DateTime from, DateTime to) async {
    final bills = await fetchBillsForRange(from, to);

    return bills.fold<double>(0.0, (total, bill) => total + bill.amount);
  }

  Future<double> getTotalPaymentsForRange(DateTime from, DateTime to) async {
    final payments = await fetchPaymentsForRange(from, to);

    return payments.fold<double>(
      0.0,
      (total, payment) => total + payment.amount,
    );
  }

  // ── Función de limpieza TOTAL (usar solo una vez) ────────────

  Future<void> deleteAllData() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Eliminar TODOS los pagos primero
      final paymentsSnap = await _db.collection('pagos_gastos').get();
      for (var doc in paymentsSnap.docs) {
        await doc.reference.delete();
      }

      // Eliminar TODOS los gastos
      final billsSnap = await _db.collection('gastos').get();
      for (var doc in billsSnap.docs) {
        await doc.reference.delete();
      }

      debugPrint(
        'Base de datos limpiada: ${paymentsSnap.docs.length} pagos y ${billsSnap.docs.length} gastos eliminados',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error al limpiar base de datos: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
