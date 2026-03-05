import 'package:cloud_firestore/cloud_firestore.dart';

class IncomePayment {
  final String? id;
  final String clientName;
  final double amount;
  final DateTime date;
  final String? notes;

  IncomePayment({
    this.id,
    required this.clientName,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'clientName': clientName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
    };
  }

  factory IncomePayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IncomePayment(
      id: doc.id,
      clientName: data['clientName'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }
}
