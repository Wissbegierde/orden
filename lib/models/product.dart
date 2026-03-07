class Product {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String defaultPayment;
  final DateTime? expiryDate;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.defaultPayment = 'efectivo',
    this.expiryDate,
  });

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final diff = expiryDate!.difference(now);
    return diff.inDays <= 30 && diff.inDays >= 0;
  }

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] as num).toDouble(),
      quantity: (data['quantity'] as num).toInt(),
      defaultPayment: data['defaultPayment'] ?? 'efectivo',
      expiryDate: data['expiryDate'] != null
          ? DateTime.parse(data['expiryDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
