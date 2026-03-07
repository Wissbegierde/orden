import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpensePaymentType { efectivo, credito, transferencia, tarjeta }

extension ExpensePaymentTypeExtension on ExpensePaymentType {
  String get label {
    switch (this) {
      case ExpensePaymentType.efectivo:
        return 'Efectivo';
      case ExpensePaymentType.credito:
        return 'Crédito';
      case ExpensePaymentType.transferencia:
        return 'Transferencia';
      case ExpensePaymentType.tarjeta:
        return 'Tarjeta';
    }
  }

  static ExpensePaymentType fromString(String val) {
    switch (val) {
      case 'Efectivo':
        return ExpensePaymentType.efectivo;
      case 'Crédito':
      case 'Credito':
        return ExpensePaymentType.credito;
      case 'Transferencia':
        return ExpensePaymentType.transferencia;
      case 'Tarjeta':
        return ExpensePaymentType.tarjeta;
      default:
        return ExpensePaymentType.efectivo;
    }
  }
}

class Expense {
  final String id;
  final String? name;  // Nombre del gasto, max 150
  final double amount;
  final DateTime date;
  final ExpensePaymentType paymentType;
  final String? providerName; // Max 150
  final String categoryId;
  final String categoryName;
  final String? notes; // Max 700
  
  // Para control de pagos a crédito
  double paidAmount;
  bool get isPaid => paymentType != ExpensePaymentType.credito || paidAmount >= amount;
  double get pendingAmount => paymentType == ExpensePaymentType.credito ? (amount - paidAmount) : 0.0;

  // Trackeo de eliminaciones lógicas y ediciones
  final bool isDeleted;
  final String? deleteReason;
  final bool isEdited;
  final double? originalAmount;

  Expense({
    required this.id,
    this.name,
    required this.amount,
    required this.date,
    required this.paymentType,
    this.providerName,
    required this.categoryId,
    required this.categoryName,
    this.notes,
    this.paidAmount = 0.0,
    this.isDeleted = false,
    this.deleteReason,
    this.isEdited = false,
    this.originalAmount,
  });

  factory Expense.fromFirestore(Map<String, dynamic> data, String id) {
    return Expense(
      id: id,
      name: data['name'],
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentType: ExpensePaymentTypeExtension.fromString(data['paymentType'] ?? 'Efectivo'),
      providerName: data['providerName'],
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? 'Sin Categoría',
      notes: data['notes'],
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0.0,
      isDeleted: data['isDeleted'] ?? false,
      deleteReason: data['deleteReason'],
      isEdited: data['isEdited'] ?? false,
      originalAmount: (data['originalAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'paymentType': paymentType.label,
      'providerName': providerName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'notes': notes,
      'paidAmount': paidAmount,
      'isDeleted': isDeleted,
      'deleteReason': deleteReason,
      'isEdited': isEdited,
      'originalAmount': originalAmount,
    };
  }

  // Necesario para que el DropdownButtonFormField pueda comparar correctamente
  // instancias creadas por el stream con el valor seleccionado.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
