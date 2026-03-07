import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType { efectivo, nequi, credito, transferencia }

extension PaymentTypeExtension on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.efectivo:
        return 'Efectivo';
      case PaymentType.nequi:
        return 'Nequi';
      case PaymentType.credito:
        return 'Crédito';
      case PaymentType.transferencia:
        return 'Transferencia';
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
  final String? productId;
  final String? productName;
  final int? quantity;
  final double amount; // Total = quantity * price
  final PaymentType paymentType;
  final String? clientName;
  final double? initialPayment; // Abono inicial dado en ventas a crédito
  final double? pendingAmount; // Saldo pendiente = amount - initialPayment
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
    this.initialPayment,
    this.pendingAmount,
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
      'initialPayment': initialPayment,
      'pendingAmount': pendingAmount,
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
      initialPayment: data['initialPayment'] != null
          ? (data['initialPayment'] as num).toDouble()
          : null,
      pendingAmount: data['pendingAmount'] != null
          ? (data['pendingAmount'] as num).toDouble()
          : null,
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }
}
