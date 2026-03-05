import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType { efectivo, nequi, credito }

extension PaymentTypeExtension on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.efectivo:
        return 'Efectivo';
      case PaymentType.nequi:
        return 'Nequi';
      case PaymentType.credito:
        return 'Crédito';
    }
  }

  static PaymentType fromString(String value) {
    return PaymentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentType.efectivo,
    );
  }
}

class IncomeSale {
  final String? id;
  final String? productId; // ID del producto elegido
  final String? productName; // Nombre del producto
  final int? quantity; // Cantidad vendida
  final double amount; // Total = quantity * price
  final PaymentType paymentType;
  final String? clientName;
  final DateTime date;
  final String? notes;

  IncomeSale({
    this.id,
    this.productId,
    this.productName,
    this.quantity,
    required this.amount,
    required this.paymentType,
    this.clientName,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'amount': amount,
      'paymentType': paymentType.name,
      'clientName': clientName,
      'date': Timestamp.fromDate(date),
      'notes': notes,
    };
  }

  factory IncomeSale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IncomeSale(
      id: doc.id,
      productId: data['productId'],
      productName: data['productName'],
      quantity: data['quantity'] != null
          ? (data['quantity'] as num).toInt()
          : null,
      amount: (data['amount'] as num).toDouble(),
      paymentType: PaymentTypeExtension.fromString(
        data['paymentType'] ?? 'efectivo',
      ),
      clientName: data['clientName'],
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }
}
