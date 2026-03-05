class Product {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String defaultPayment;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.defaultPayment = 'efectivo',
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] as num).toDouble(),
      quantity: (data['quantity'] as num).toInt(),
      defaultPayment: data['defaultPayment'] ?? 'efectivo',
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
