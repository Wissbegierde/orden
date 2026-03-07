import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/shopping.dart';

class ShoppingProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // ── Compras ────────────────────────────────────────────────────

  Stream<List<Shopping>> shoppingsStream() {
    return _db.collection('compras').snapshots().map((snap) {
      final shoppings = snap.docs.map(Shopping.fromFirestore).toList();

      final active = shoppings.where((s) => !s.isDeleted).toList();
      active.sort((a, b) => b.date.compareTo(a.date));

      return active;
    });
  }

  Stream<List<Shopping>> shoppingsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return _db
        .collection('compras')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
      final shoppings = snap.docs.map(Shopping.fromFirestore).toList();

      final active = shoppings.where((s) => !s.isDeleted).toList();
      active.sort((a, b) => b.date.compareTo(a.date));

      return active;
    });
  }

  Stream<List<Shopping>> unpaidShoppings() {
    return _db
        .collection('compras')
        .where('paid', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final shoppings = snap.docs.map(Shopping.fromFirestore).toList();

      final active = shoppings.where((s) => !s.isDeleted).toList();
      active.sort((a, b) => b.date.compareTo(a.date));

      return active;
    });
  }

  /// Compras con saldo pendiente (balance > 0), considerando pagos parciales.
  /// Se actualiza cuando cambian compras o pagos.
  Stream<List<PurchaseWithBalance>> unpaidShoppingsWithBalance() {
    final controller = StreamController<List<PurchaseWithBalance>>.broadcast();

    Future<void> compute() async {
      final comprasSnap = await _db.collection('compras').get();
      final paymentsSnap = await _db.collection('pagos_compras').get();

      final shoppings = comprasSnap.docs
          .map(Shopping.fromFirestore)
          .where((s) => !s.isDeleted)
          .toList();

      final paidByShopping = <String, double>{};
      for (final doc in paymentsSnap.docs) {
        final p = ShoppingPayment.fromFirestore(doc);
        paidByShopping[p.shoppingId] =
            (paidByShopping[p.shoppingId] ?? 0) + p.amount;
      }

      final result = <PurchaseWithBalance>[];
      for (final s in shoppings) {
        final totalPaid = paidByShopping[s.id] ?? 0;
        final balance = s.amount - totalPaid;
        if (balance > 0) {
          result.add(PurchaseWithBalance(shopping: s, balance: balance));
        }
      }
      result.sort((a, b) => b.shopping.date.compareTo(a.shopping.date));
      if (!controller.isClosed) controller.add(result);
    }

    final sub1 = _db.collection('compras').snapshots().listen((_) => compute());
    final sub2 =
        _db.collection('pagos_compras').snapshots().listen((_) => compute());

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    compute();
    return controller.stream;
  }

  // ── CRUD Compras ───────────────────────────────────────────────

  Future<void> addShopping(Shopping shopping) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef =
          await _db.collection('compras').add(shopping.toFirestore());

      if (shopping.paid) {
        final payment = ShoppingPayment(
          shoppingId: docRef.id,
          amount: shopping.amount,
          date: shopping.date,
          notes: 'Pago automático al registrar compra',
        );
        await _db.collection('pagos_compras').add(payment.toFirestore());
      }

      if (shopping.productId != null &&
          shopping.quantity != null &&
          shopping.quantity! > 0) {
        await _db.collection('productos').doc(shopping.productId!).update({
          'quantity': FieldValue.increment(shopping.quantity!),
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

  Future<void> updateShopping(String shoppingId, Shopping shopping) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _db
          .collection('compras')
          .doc(shoppingId)
          .update(shopping.toFirestore());
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  // ── Soft Delete ────────────────────────────────────────────────

  Future<void> softDeleteShopping(
    String shoppingId,
    String reason,
    String deletedBy,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final paymentsSnap = await _db
          .collection('pagos_compras')
          .where('shoppingId', isEqualTo: shoppingId)
          .limit(1)
          .get();

      if (paymentsSnap.docs.isNotEmpty) {
        throw Exception(
          'No se puede eliminar esta compra porque tiene pagos registrados.',
        );
      }

      await _db.collection('compras').doc(shoppingId).update({
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

  // ── Pagos de Compras ───────────────────────────────────────────

  Stream<List<ShoppingPayment>> paymentsStream() {
    return _db.collection('pagos_compras').snapshots().map((snap) {
      final payments =
          snap.docs.map(ShoppingPayment.fromFirestore).toList();

      payments.sort((a, b) => b.date.compareTo(a.date));

      return payments;
    });
  }

  Stream<List<ShoppingPayment>> paymentsForShopping(String shoppingId) {
    return _db
        .collection('pagos_compras')
        .where('shoppingId', isEqualTo: shoppingId)
        .snapshots()
        .map((snap) {
      final payments =
          snap.docs.map(ShoppingPayment.fromFirestore).toList();

      payments.sort((a, b) => b.date.compareTo(a.date));

      return payments;
    });
  }

  Future<void> addPayment(ShoppingPayment payment) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.collection('pagos_compras').add(payment.toFirestore());

      final shoppingDoc =
          await _db.collection('compras').doc(payment.shoppingId).get();
      if (!shoppingDoc.exists) {
        throw Exception('La compra no existe');
      }

      final shopping = Shopping.fromFirestore(shoppingDoc);

      final paymentsSnap = await _db
          .collection('pagos_compras')
          .where('shoppingId', isEqualTo: payment.shoppingId)
          .get();

      final totalPaid = paymentsSnap.docs
          .map(ShoppingPayment.fromFirestore)
          .fold<double>(0.0, (sum, p) => sum + p.amount);

      if (totalPaid >= shopping.amount && !shopping.paid) {
        await _db.collection('compras').doc(payment.shoppingId).update({
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

  Future<List<Shopping>> fetchShoppingsForRange(
    DateTime from,
    DateTime to,
  ) async {
    final snap = await _db
        .collection('compras')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .get();

    final shoppings = snap.docs.map(Shopping.fromFirestore).toList();

    final active = shoppings.where((s) => !s.isDeleted).toList();

    active.sort((a, b) => b.date.compareTo(a.date));

    return active;
  }

  /// Todas las compras (para reporte Por Pagar: deudas con saldo).
  Future<List<Shopping>> fetchAllShoppings() async {
    final snap = await _db.collection('compras').get();
    final shoppings = snap.docs.map(Shopping.fromFirestore).toList();
    final active = shoppings.where((s) => !s.isDeleted).toList();
    active.sort((a, b) => b.date.compareTo(a.date));
    return active;
  }

  Future<List<ShoppingPayment>> fetchPaymentsForRange(
    DateTime from,
    DateTime to,
  ) async {
    final snap = await _db
        .collection('pagos_compras')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .get();

    final payments = snap.docs.map(ShoppingPayment.fromFirestore).toList();

    payments.sort((a, b) => b.date.compareTo(a.date));

    return payments;
  }

  /// Total pagado por cada compra (para calcular saldo pendiente).
  Future<Map<String, double>> fetchTotalPaidByShoppingId() async {
    final snap = await _db.collection('pagos_compras').get();
    final map = <String, double>{};
    for (final doc in snap.docs) {
      final p = ShoppingPayment.fromFirestore(doc);
      map[p.shoppingId] = (map[p.shoppingId] ?? 0) + p.amount;
    }
    return map;
  }
}

