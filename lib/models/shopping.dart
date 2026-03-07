import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType { efectivo, transferencia, tarjeta, credito }

extension PaymentTypeExtension on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.efectivo:
        return 'Efectivo';
      case PaymentType.transferencia:
        return 'Transferencia';
      case PaymentType.tarjeta:
        return 'Tarjeta';
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

class Shopping {
  final String? id;
  final String description;
  final double amount;
  final PaymentType paymentType;
  final DateTime date;
  final bool paid;
  final String? providerName;
  final String? productId;
  final int? quantity;

  // Soft delete fields
  final DateTime? deletedAt;
  final String? deletedReason;
  final String? deletedBy;

  Shopping({
    this.id,
    required this.description,
    required this.amount,
    required this.paymentType,
    required this.date,
    this.paid = false,
    this.providerName,
    this.productId,
    this.quantity,
    this.deletedAt,
    this.deletedReason,
    this.deletedBy,
  });

  // Check if bill is deleted
  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'paymentType': paymentType.name,
      'date': Timestamp.fromDate(date),
      'paid': paid,
      'providerName': providerName,
      'productId': productId,
      'quantity': quantity,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedReason': deletedReason,
      'deletedBy': deletedBy,
    };
  }

  factory Shopping.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Shopping(
      id: doc.id,
      description: data['description'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      paymentType: PaymentTypeExtension.fromString(
        data['paymentType'] ?? 'efectivo',
      ),
      date: (data['date'] as Timestamp).toDate(),
      paid: data['paid'] ?? false,
      providerName: data['providerName'],
      productId: data['productId'],
      quantity: data['quantity'] != null
          ? (data['quantity'] as num).toInt()
          : null,
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
      deletedReason: data['deletedReason'],
      deletedBy: data['deletedBy'],
    );
  }
}

class ShoppingPayment {
  final String? id;
  final String shoppingId;
  final double amount;
  final DateTime date;
  final String? notes;

  ShoppingPayment({
    this.id,
    required this.shoppingId,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'shoppingId': shoppingId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
    };
  }

  factory ShoppingPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingPayment(
      id: doc.id,
      shoppingId: data['shoppingId'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }
}
