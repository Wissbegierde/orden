import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentType { efectivo, nequi, transferencia, tarjeta }

enum BillCategory { arriendo, servicios, salarios, utiles, otros }

extension PaymentTypeExtension on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.efectivo:
        return 'Efectivo';
      case PaymentType.nequi:
        return 'Nequi';
      case PaymentType.transferencia:
        return 'Transferencia';
      case PaymentType.tarjeta:
        return 'Tarjeta';
    }
  }

  static PaymentType fromString(String value) {
    return PaymentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentType.efectivo,
    );
  }
}

extension BillCategoryExtension on BillCategory {
  String get label {
    switch (this) {
      case BillCategory.arriendo:
        return 'Arriendo';
      case BillCategory.servicios:
        return 'Servicios';
      case BillCategory.salarios:
        return 'Salarios';
      case BillCategory.utiles:
        return 'Útiles de Aseo';
      case BillCategory.otros:
        return 'Otros';
    }
  }

  static BillCategory fromString(String value) {
    return BillCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BillCategory.otros,
    );
  }
}

class Bill {
  final String? id;
  final String description;
  final double amount;
  final PaymentType paymentType;
  final BillCategory?
  category; // Nullable para elegir entre predefinida o personalizada
  final String? customCategory; // Para categorías personalizadas
  final DateTime date;
  final bool paid;
  final String? providerName;
  final String? notes;

  // Soft delete fields
  final DateTime? deletedAt;
  final String? deletedReason;
  final String? deletedBy;

  Bill({
    this.id,
    required this.description,
    required this.amount,
    required this.paymentType,
    this.category,
    this.customCategory,
    required this.date,
    this.paid = false,
    this.providerName,
    this.notes,
    this.deletedAt,
    this.deletedReason,
    this.deletedBy,
  });

  // Check if bill is deleted
  bool get isDeleted => deletedAt != null;

  String get categoryLabel {
    if (customCategory != null) {
      return customCategory!;
    }
    return category?.label ?? 'Otros';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'paymentType': paymentType.name,
      'category': category?.name,
      'customCategory': customCategory,
      'date': Timestamp.fromDate(date),
      'paid': paid,
      'providerName': providerName,
      'notes': notes,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedReason': deletedReason,
      'deletedBy': deletedBy,
    };
  }

  factory Bill.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Bill(
      id: doc.id,
      description: data['description'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      paymentType: PaymentTypeExtension.fromString(
        data['paymentType'] ?? 'efectivo',
      ),
      category: data['category'] != null
          ? BillCategoryExtension.fromString(data['category'])
          : null,
      customCategory: data['customCategory'],
      date: (data['date'] as Timestamp).toDate(),
      paid: data['paid'] ?? false,
      providerName: data['providerName'],
      notes: data['notes'],
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
      deletedReason: data['deletedReason'],
      deletedBy: data['deletedBy'],
    );
  }
}

class BillPayment {
  final String? id;
  final String billId;
  final double amount;
  final DateTime date;
  final String? notes;

  BillPayment({
    this.id,
    required this.billId,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'billId': billId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
    };
  }

  factory BillPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BillPayment(
      id: doc.id,
      billId: data['billId'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }
}
