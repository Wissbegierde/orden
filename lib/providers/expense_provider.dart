import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/expense_payment.dart';
import '../models/expense_category.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // ── Categorías ──────────────────────────────────────────────────
  Stream<List<ExpenseCategory>> categoriesStream() {
    return _db
        .collection('gastos_categorias')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ExpenseCategory.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  Future<void> addCategory(String categoryName) async {
    _setLoading(true);
    try {
      final exists = await _db.collection('gastos_categorias').where('name', isEqualTo: categoryName).get();
      if (exists.docs.isEmpty) {
        await _db.collection('gastos_categorias').add({'name': categoryName});
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Gastos (No eliminados) ──────────────────────────────────────
  Stream<List<Expense>> expensesStream() {
    return _db
        .collection('gastos')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Expense.fromFirestore(d.data(), d.id))
              .where((e) => !e.isDeleted) // Filtrar localmente para evitar requerir índice compuesto
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date)); // Ordenar localmente
          return list;
        });
  }

  // Flujo para la pantalla de eliminados y editados
  Stream<List<Expense>> deletedOrEditedExpensesStream() {
    return _db
        .collection('gastos')
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => Expense.fromFirestore(d.data(), d.id))
              .where((e) => e.isDeleted || e.isEdited)
              .toList()
              ..sort((a, b) => b.date.compareTo(a.date));
        });
  }

  Future<void> addExpense(Expense expense) async {
    _setLoading(true);
    try {
      if (expense.amount <= 0 || expense.amount > 9999999999) {
        throw Exception("El monto debe ser mayor a 0 y permitido.");
      }
      final today = DateTime.now();
      if (expense.date.isAfter(DateTime(today.year, today.month, today.day, 23, 59, 59))) {
         throw Exception("No se permiten pagos con fecha futura");
      }
      
      await _db.collection('gastos').add(expense.toFirestore());
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> editExpense(Expense expense, double newAmount, String newName, String newNotes, ExpenseCategory newCategory, String? providerName) async {
    _setLoading(true);
    try {
      if (expense.paidAmount > 0) {
        throw Exception("No se puede editar un gasto que ya tiene abonos.");
      }
      if (newAmount <= 0) {
         throw Exception("El monto debe ser mayor a 0");
      }

      await _db.collection('gastos').doc(expense.id).update({
        'name': newName,
        'amount': newAmount,
        'notes': newNotes,
        'categoryId': newCategory.id,
        'categoryName': newCategory.name,
        'providerName': providerName,
        'isEdited': true,
        'originalAmount': expense.originalAmount ?? expense.amount,
      });
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteExpense(Expense expense, String reason) async {
    _setLoading(true);
    try {
       if (expense.paidAmount > 0) {
          throw Exception("No se puede eliminar un gasto que ya tiene abonos.");
       }

       await _db.collection('gastos').doc(expense.id).update({
         'isDeleted': true,
         'deleteReason': reason,
       });
    } catch(e) {
       _error = e.toString();
       throw e;
    } finally {
       _setLoading(false);
    }
  }

  // ── Abonos de crédito ──────────────────────────────────────────
  Stream<List<ExpensePayment>> paymentsStream(String expenseId) {
    return _db
        .collection('gastos_pagos')
        .where('expenseId', isEqualTo: expenseId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ExpensePayment.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> addPayment(Expense expense, double paymentAmount, DateTime paymentDate, String notes) async {
    _setLoading(true);
    try {
      if (paymentAmount <= 0) {
        throw Exception("El monto debe ser mayor a 0");
      }
      if (paymentAmount > expense.pendingAmount) {
        throw Exception("El monto supera el valor pendiente");
      }
      final today = DateTime.now();
      if (paymentDate.isAfter(DateTime(today.year, today.month, today.day, 23, 59, 59))) {
        throw Exception("No se permiten pagos con fecha futura");
      }

      // Usar transacción para confirmar que el abono es sólido.
      final expenseRef = _db.collection('gastos').doc(expense.id);
      final paymentRef = _db.collection('gastos_pagos').doc();

      await _db.runTransaction((transaction) async {
        final expenseDoc = await transaction.get(expenseRef);
        if (!expenseDoc.exists) throw Exception("Gasto no encontrado");
        
        final currentPaid = (expenseDoc.data()?['paidAmount'] as num?)?.toDouble() ?? 0.0;
        final currentAmount = (expenseDoc.data()?['amount'] as num?)?.toDouble() ?? 0.0;
        final pending = currentAmount - currentPaid;

        if (paymentAmount > pending) {
          throw Exception("El monto ($paymentAmount) supera el valor pendiente ($pending)");
        }

        final newPaidAmount = currentPaid + paymentAmount;
        transaction.update(expenseRef, {'paidAmount': newPaidAmount});

        transaction.set(paymentRef, {
           'expenseId': expense.id,
           'amount': paymentAmount,
           'date': Timestamp.fromDate(paymentDate),
           'notes': notes,
        });
      });

    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // ── Reportes ──────────────────────────────────────────────────
  Future<List<Expense>> fetchExpensesForRange(DateTime from, DateTime to) async {
    // Traemos todo y filtramos localmente para evitar requerir índice compuesto en Firestore.
    final snap = await _db.collection('gastos').get();
    final all = snap.docs.map((d) => Expense.fromFirestore(d.data(), d.id)).toList();
    return all
        .where((e) =>
            !e.isDeleted &&
            !e.date.isBefore(from) &&
            e.date.isBefore(to))
        .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
