import 'package:cloud_firestore/cloud_firestore.dart';

class ExpensePayment {
  final String id;
  final String expenseId;
  final double amount;
  final DateTime date;
  final String? notes;

  ExpensePayment({
    required this.id,
    required this.expenseId,
    required this.amount,
    required this.date,
    this.notes,
  });

  factory ExpensePayment.fromFirestore(Map<String, dynamic> data, String id) {
    return ExpensePayment(
      id: id,
      expenseId: data['expenseId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'expenseId': expenseId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
    };
  }
}
