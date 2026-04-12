class AppUser {
  const AppUser({required this.name, required this.email});

  final String name;
  final String email;
}

class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.district,
    this.reference = '',
  });

  final String id;
  final String label;
  final String street;
  final String district;
  final String reference;

  String get formatted => '$street - $district';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'street': street,
      'district': district,
      'reference': reference,
    };
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Casa',
      street: json['street'] as String? ?? '',
      district: json['district'] as String? ?? 'Lince',
      reference: json['reference'] as String? ?? '',
    );
  }
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String productId;
  final String name;
  final double price;
  final int quantity;

  double get lineTotal => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.createdAt,
    required this.deliveryEta,
    required this.storeName,
    required this.address,
    required this.items,
    required this.subtotal,
    required this.deliveryCost,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.deliveryNote,
  });

  final String id;
  final DateTime createdAt;
  final String deliveryEta;
  final String storeName;
  final String address;
  final List<OrderLine> items;
  final double subtotal;
  final double deliveryCost;
  final double discount;
  final double total;
  final String paymentMethod;
  final String status;
  final String deliveryNote;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'deliveryEta': deliveryEta,
      'storeName': storeName,
      'address': address,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryCost': deliveryCost,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status,
      'deliveryNote': deliveryNote,
    };
  }

  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    return OrderRecord(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      deliveryEta: json['deliveryEta'] as String? ?? '30 min',
      storeName: json['storeName'] as String? ?? 'Licoreria WAS-K',
      address: json['address'] as String? ?? '',
      items: rawItems.map(OrderLine.fromJson).toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryCost: (json['deliveryCost'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'Efectivo',
      status: json['status'] as String? ?? 'En camino',
      deliveryNote: json['deliveryNote'] as String? ?? '',
    );
  }
}
