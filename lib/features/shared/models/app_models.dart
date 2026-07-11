class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.uuid,
    this.companyId,
    this.supplierId,
    this.status,
    this.isVerified,
  });

  final String id;
  final String? uuid;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? companyId;
  final String? supplierId;
  final String? status;
  final bool? isVerified;

  String get name {
    final full =
        [firstName, lastName].where((part) => part.isNotEmpty).join(' ');
    return full.trim();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _asString(json['id']) ?? _asString(json['uuid']) ?? '',
      uuid: _asString(json['uuid']),
      firstName: _asString(json['firstName']) ?? '',
      lastName: _asString(json['lastName']) ?? '',
      email: _asString(json['email']) ?? '',
      role: _asString(json['role']) ?? 'BUSINESS',
      companyId: _asString(json['companyId']),
      supplierId: _asString(json['supplierId']),
      status: _asString(json['status']),
      isVerified: _asBool(json['isVerified']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'companyId': companyId,
      'supplierId': supplierId,
      'status': status,
      'isVerified': isVerified,
    };
  }
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: _asString(json['accessToken']) ?? '',
      refreshToken: _asString(json['refreshToken']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.category,
    this.supplierId,
    this.brand,
    this.description,
    this.isActive,
  });

  final String id;
  final String name;
  final double price;
  final String? category;
  final String? supplierId;
  final String? brand;
  final String? description;
  final bool? isActive;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _asString(json['id']) ?? _asString(json['uuid']) ?? '',
      name: _asString(json['name']) ?? '',
      price: _asDouble(json['price'] ?? json['unitPrice']),
      category: _asString(json['category']),
      // El backend identifica la tienda con businessId; lo guardamos como
      // supplierId para la lógica de carrito/checkout del cliente.
      supplierId: _asString(json['supplierId']) ?? _asString(json['businessId']),
      brand: _asString(json['brand']),
      description: _asString(json['description']),
      isActive: _asBool(json['isActive']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'supplierId': supplierId,
      'brand': brand,
      'description': description,
      'isActive': isActive,
    };
  }
}

class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.status,
    this.isVerified,
    this.email,
    this.phone,
  });

  final String id;
  final String name;
  final String? status;
  final bool? isVerified;
  final String? email;
  final String? phone;

  factory Supplier.fromJson(Map<String, dynamic> json) {
    // Una "tienda" viene del backend como Business: usa companyName y
    // operationalStatus. Mantenemos compatibilidad con la forma antigua.
    return Supplier(
      id: _asString(json['id']) ?? _asString(json['uuid']) ?? '',
      name: _asString(json['name']) ?? _asString(json['companyName']) ?? '',
      status: _asString(json['status']) ?? _asString(json['operationalStatus']),
      isVerified: _asBool(json['isVerified']),
      email: _asString(json['email']),
      phone: _asString(json['phone']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'isVerified': isVerified,
      'email': email,
      'phone': phone,
    };
  }
}

class Business {
  const Business({
    required this.id,
    required this.name,
    this.status,
  });

  final String id;
  final String name;
  final String? status;

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: _asString(json['id']) ?? _asString(json['uuid']) ?? '',
      name: _asString(json['name']) ?? '',
      status: _asString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
    };
  }
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
    required this.quantity,
    this.name,
    this.price,
  });

  final String productId;
  final int quantity;
  final String? name;
  final double? price;

  double get lineTotal => (price ?? 0) * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
    };
  }

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      productId: json['productId'] as String? ?? '',
      name: _asString(json['name']),
      price: _asDouble(json['price'] ?? json['unitPrice']),
      quantity: _asInt(json['quantity']) ?? 1,
    );
  }
}

class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.total,
    required this.status,
    this.deliveryEta,
    this.storeName,
    this.address,
    this.subtotal,
    this.deliveryCost,
    this.discount,
    this.paymentMethod,
    this.deliveryNote,
    this.businessId,
    this.supplierId,
  });

  final String id;
  final DateTime createdAt;
  final List<OrderLine> items;
  final double total;
  final String status;
  final String? deliveryEta;
  final String? storeName;
  final String? address;
  final double? subtotal;
  final double? deliveryCost;
  final double? discount;
  final String? paymentMethod;
  final String? deliveryNote;
  final String? businessId;
  final String? supplierId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status,
      'deliveryEta': deliveryEta,
      'storeName': storeName,
      'address': address,
      'subtotal': subtotal,
      'deliveryCost': deliveryCost,
      'discount': discount,
      'paymentMethod': paymentMethod,
      'deliveryNote': deliveryNote,
      'businessId': businessId,
      'supplierId': supplierId,
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
      items: rawItems.map(OrderLine.fromJson).toList(),
      total: _asDouble(json['total'] ?? json['grandTotal']),
      status: _asString(json['status']) ?? 'PENDIENTE',
      deliveryEta: _asString(json['deliveryEta']),
      storeName: _asString(json['storeName'] ?? json['supplierName']),
      address: _asString(json['address']),
      subtotal: _asDouble(json['subtotal']),
      deliveryCost: _asDouble(json['deliveryCost']),
      discount: _asDouble(json['discount']),
      paymentMethod: _asString(json['paymentMethod']),
      deliveryNote: _asString(json['deliveryNote'] ?? json['notes']),
      businessId: _asString(json['businessId']),
      supplierId: _asString(json['supplierId']),
    );
  }
}

String? _asString(dynamic value) {
  if (value is String) {
    return value;
  }
  if (value == null) {
    return null;
  }
  return value.toString();
}

double _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

bool? _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return null;
}
