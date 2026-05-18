import 'package:flutter/foundation.dart';

class CartItem {
  const CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.supplierId,
  });

  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? supplierId;

  CartItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    String? supplierId,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      supplierId: supplierId ?? this.supplierId,
    );
  }

  double get lineTotal => price * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = <String, CartItem>{};

  Map<String, CartItem> get items => Map<String, CartItem>.unmodifiable(_items);

  List<CartItem> get itemList => _items.values.toList(growable: false);

  int get totalItems {
    if (_items.isEmpty) {
      return 0;
    }
    return _items.values
        .map((item) => item.quantity)
        .reduce((value, element) => value + element);
  }

  double get subtotal {
    if (_items.isEmpty) {
      return 0;
    }
    return _items.values
        .map((item) => item.lineTotal)
        .reduce((value, element) => value + element);
  }

  void addItem({
    required String productId,
    required String name,
    required double price,
    int quantity = 1,
    String? supplierId,
  }) {
    final current = _items[productId];
    if (current == null) {
      _items[productId] = CartItem(
        productId: productId,
        name: name,
        price: price,
        quantity: quantity,
        supplierId: supplierId,
      );
    } else {
      _items[productId] =
          current.copyWith(quantity: current.quantity + quantity);
    }
    notifyListeners();
  }

  void incrementItem(String productId) {
    final current = _items[productId];
    if (current == null) {
      return;
    }
    _items[productId] = current.copyWith(quantity: current.quantity + 1);
    notifyListeners();
  }

  void decrementItem(String productId) {
    final current = _items[productId];
    if (current == null) {
      return;
    }
    if (current.quantity <= 1) {
      _items.remove(productId);
    } else {
      _items[productId] = current.copyWith(quantity: current.quantity - 1);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
