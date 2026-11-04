import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};
  String paymentMethod = 'cash';
  double discountPercent = 0; // 10 means 10%
  bool submitting = false;
  String? error;

  List<CartItem> get items => _items.values.toList();
  int get count => _items.values.fold(0, (s, i) => s + i.qty);
  double get subtotal =>
      _items.values.fold(0, (s, i) => s + i.product.price * i.qty);

  // Discount in dollars, calculated from the percentage
  double get discount => (subtotal * discountPercent).round() / 100;
  double get total => (subtotal - discount).clamp(0, double.infinity);

  int qtyOf(int productId) => _items[productId]?.qty ?? 0;

  void add(Product p) {
    if (_items.containsKey(p.id)) {
      _items[p.id]!.qty++;
    } else {
      _items[p.id] = CartItem(p, 1);
    }
    notifyListeners();
  }

  void decrease(Product p) {
    final item = _items[p.id];
    if (item == null) return;
    item.qty--;
    if (item.qty <= 0) _items.remove(p.id);
    notifyListeners();
  }

  void setPayment(String m) {
    paymentMethod = m;
    notifyListeners();
  }

  void setDiscountPercent(double d) {
    discountPercent = d.clamp(0, 100).toDouble();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    discountPercent = 0;
    paymentMethod = 'cash';
    notifyListeners();
  }

  Future<Map<String, dynamic>?> checkout() async {
    submitting = true;
    error = null;
    notifyListeners();
    try {
      final res = await ApiClient.dio.post('/orders', data: {
        'payment_method': paymentMethod,
        'discount_percent': discountPercent,
        'items': items
            .map((i) => {'product_id': i.product.id, 'quantity': i.qty})
            .toList(),
      });
      final order = Map<String, dynamic>.from(res.data);
      clear();
      return order;
    } on DioException catch (e) {
      error = e.response?.data is Map
          ? (e.response!.data['message'] ?? 'Order failed')
          : 'Cannot connect to server';
      return null;
    } finally {
      submitting = false;
      notifyListeners();
    }
  }
}