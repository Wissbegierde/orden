import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseCategory {
  final String id;
  final String name;

  ExpenseCategory({
    required this.id,
    required this.name,
  });

  factory ExpenseCategory.fromFirestore(Map<String, dynamic> data, String id) {
    return ExpenseCategory(
      id: id,
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name};
  }

  // Necesario para que el DropdownButtonFormField pueda comparar correctamente
  // las instancias que crea el stream con el valor seleccionado previamente.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
