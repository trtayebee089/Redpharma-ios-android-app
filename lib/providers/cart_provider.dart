import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String? brand;
  final String? unit;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.brand,
    required this.unit,
    this.quantity = 1,
  });

  @override
  String toString() {
    return 'CartItem(id: $id, name: $name, price: $price, quantity: $quantity, brand: $brand, unit: $unit)';
  }
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.values.fold(0, (sum, item) => sum + item.price * item.quantity);

  void addItem(Map<String, dynamic> product) {
    final id = product['id'].toString();
    
    if (_items.containsKey(id)) {
      _items[id]!.quantity += 1;
    } else {
      _items[id] = CartItem(
        id: id,
        name: product['name'] ?? 'Unknown',
        price: double.tryParse(product['price'].toString()) ?? 0,
        imageUrl: product['image'] ?? 'https://placehold.co/400',
        brand: product['brand'] != null && product['brand'] is Map
            ? product['brand']['title'] ?? 'No Brand'
            : product['brand']?.toString(),
        unit: product['unit'] != null && product['unit'] is Map
            ? product['unit']['unit_code'] ?? 'unit' : product['unit']?.toString(),
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void decreaseQuantity(String id) {
    if (_items.containsKey(id) && _items[id]!.quantity > 1) {
      _items[id]!.quantity -= 1;
    } else {
      _items.remove(id);
    }
    notifyListeners();
  }
}
