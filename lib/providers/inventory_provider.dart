import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';

class InventoryProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // Stream of all products
  Stream<List<Product>> get stockStream {
    return _db
        .collection('productos')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Product.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  // Create or update a product manually
  Future<void> addOrUpdateProduct(Product product) async {
    _setLoading(true);
    try {
      final data = {
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'defaultPayment': product.defaultPayment,
      };

      if (product.id.isEmpty || product.id == 'new') {
        await _db.collection('productos').add(data);
      } else {
        await _db.collection('productos').doc(product.id).update(data);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    _setLoading(true);
    try {
      await _db.collection('productos').doc(productId).delete();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
