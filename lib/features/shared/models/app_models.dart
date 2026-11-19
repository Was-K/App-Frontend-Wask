import '../../../core/config/app_config.dart';

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
    this.phone,
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
  final String? phone;

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
      role: _asString(json['role']) ?? 'CUSTOMER',
      companyId: _asString(json['companyId']),
      supplierId: _asString(json['supplierId']),
      status: _asString(json['status']),
      isVerified: _asBool(json['isVerified']),
      phone: _asString(json['phone']),
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
      'phone': phone,
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
    this.imageUrl,
    this.availableStock = 0,
    this.warehouseNames = const <String>[],
    this.volumeMl,
    this.storeName,
    this.sku,
  });

  final String id;
  final String name;
  final double price;
  final String? category;
  final String? supplierId;
  final String? brand;
  final String? description;
  final bool? isActive;
  final String? imageUrl;
  final int availableStock;
  final List<String> warehouseNames;
  final int? volumeMl;
  final String? storeName;
  final String? sku;

  factory Product.fromJson(Map<String, dynamic> json) {
    final businessMap = json['business'] is Map<String, dynamic>
        ? json['business'] as Map<String, dynamic>
        : null;

    return Product(
      id: _asString(json['id']) ?? _asString(json['uuid']) ?? '',
      name: _asString(json['name']) ?? '',
      price: _asDouble(json['price'] ?? json['unitPrice']),
      category: _asString(json['category']),
      // El backend identifica la tienda con businessId; lo guardamos como
      // supplierId para la logica de carrito/checkout del cliente.
      supplierId: _asString(json['supplierId']) ??
          _asString(json['businessId']) ??
          _asString(businessMap?['id']),
      brand: _asString(json['brand']),
      description: _asString(json['description']),
      isActive: _asBool(json['isActive']) ??
          (_asString(json['status'])?.toUpperCase() == 'ACTIVE' ? true : null),
      imageUrl: _resolveImageUrl(json),
      availableStock: _parseAvailableStock(json),
      warehouseNames: _parseWarehouseNames(json),
      volumeMl: _asInt(json['volumeMl']),
      storeName: _asString(json['storeName']) ??
          _asString(json['businessName']) ??
          _asString(businessMap?['companyName']) ??
          _asString(businessMap?['name']),
      sku: _asString(json['sku']),
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
      'imageUrl': imageUrl,
      'availableStock': availableStock,
      'warehouseNames': warehouseNames,
      'volumeMl': volumeMl,
      'storeName': storeName,
      'sku': sku,
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
    this.address,
    this.logo,
    this.industry,
    this.latitude,
    this.longitude,
    this.isOpenNow = true,
    this.openTime,
    this.closeTime,
    this.deliveryRadiusKm,
    this.yapeNumber,
    this.plinNumber,
  });

  final String id;
  final String name;
  final String? status;
  final bool? isVerified;
  final String? email;
  final String? phone;
  final String? address;
  final String? logo;
  final String? industry;
  final double? latitude;
  final double? longitude;
  final bool isOpenNow;
  final String? openTime;
  final String? closeTime;
  final double? deliveryRadiusKm;
  final String? yapeNumber;
  final String? plinNumber;

  bool canDeliverDistance(double? distanceKm) {
    if (distanceKm == null || deliveryRadiusKm == null || deliveryRadiusKm! <= 0) {
      return true;
    }
    return distanceKm <= deliveryRadiusKm!;
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final opStatus =
        _asString(json['status']) ?? _asString(json['operationalStatus']);
    final verificationStatus = _asString(json['verificationStatus']);
    final explicitVerified = _asBool(json['isVerified']);
    // /business/shops solo devuelve negocios VERIFIED.
    final resolvedVerified = explicitVerified ??
        (verificationStatus != null
            ? verificationStatus.toUpperCase() == 'VERIFIED'
            : true);

    final rawLogo = _asString(json['logo']);
    final explicitOpen = _asBool(json['isOpenNow']);
    final resolvedOpen = explicitOpen ??
        (opStatus?.toUpperCase() != 'PAUSED' &&
            opStatus?.toUpperCase() != 'SUSPENDED');

    return Supplier(
      id: _asString(json['id']) ?? _asString(json['uuid']) ?? '',
      name: _asString(json['name']) ?? _asString(json['companyName']) ?? '',
      status: opStatus,
      isVerified: resolvedVerified,
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      address: _asString(json['address']),
      logo: rawLogo == null || rawLogo.trim().isEmpty
          ? null
          : _normalizeMediaUrl(rawLogo),
      industry: _asString(json['industry']),
      latitude: _asNullableDouble(json['latitude']),
      longitude: _asNullableDouble(json['longitude']),
      isOpenNow: resolvedOpen,
      openTime: _asString(json['openTime']),
      closeTime: _asString(json['closeTime']),
      deliveryRadiusKm: _asNullableDouble(json['deliveryRadiusKm']),
      yapeNumber: _asString(json['yapeNumber']),
      plinNumber: _asString(json['plinNumber']),
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
      'address': address,
      'logo': logo,
      'industry': industry,
      'latitude': latitude,
      'longitude': longitude,
      'isOpenNow': isOpenNow,
      'openTime': openTime,
      'closeTime': closeTime,
      'deliveryRadiusKm': deliveryRadiusKm,
      'yapeNumber': yapeNumber,
      'plinNumber': plinNumber,
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
      name: _asString(json['name']) ?? _asString(json['companyName']) ?? '',
      status: _asString(json['status']) ?? _asString(json['operationalStatus']),
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
    this.apartmentOrInterior = '',
    this.intercom = '',
    this.reference = '',
    this.contactPhone = '',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String label;
  final String street;
  final String district;
  final String apartmentOrInterior;
  final String intercom;
  final String reference;
  final String contactPhone;
  final double? latitude;
  final double? longitude;

  String get formatted => '$street - $district';

  String get formattedFullAddress {
    final parts = <String>[
      if (street.trim().isNotEmpty) street.trim(),
      if (apartmentOrInterior.trim().isNotEmpty) apartmentOrInterior.trim(),
      if (district.trim().isNotEmpty) district.trim(),
      if (intercom.trim().isNotEmpty) 'Timbre: ${intercom.trim()}',
      if (reference.trim().isNotEmpty) 'Ref: ${reference.trim()}',
      if (contactPhone.trim().isNotEmpty) 'Cel: ${contactPhone.trim()}',
    ];
    return parts.join(' · ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'street': street,
      'district': district,
      'apartmentOrInterior': apartmentOrInterior,
      'intercom': intercom,
      'reference': reference,
      'contactPhone': contactPhone,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Casa',
      street: json['street'] as String? ?? '',
      district: json['district'] as String? ?? 'Miraflores',
      apartmentOrInterior: json['apartmentOrInterior'] as String? ?? '',
      intercom: json['intercom'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      latitude: _asNullableDouble(json['latitude']),
      longitude: _asNullableDouble(json['longitude']),
    );
  }
}

class LoyaltyStatus {
  const LoyaltyStatus({
    required this.deliveredOrders,
    required this.targetOrders,
    required this.currentCycleProgress,
    required this.freeDeliveriesAvailable,
    required this.hasFreeDeliveryReward,
    required this.nextRewardIn,
    required this.rewardLabel,
  });

  final int deliveredOrders;
  final int targetOrders;
  final int currentCycleProgress;
  final int freeDeliveriesAvailable;
  final bool hasFreeDeliveryReward;
  final int nextRewardIn;
  final String rewardLabel;

  factory LoyaltyStatus.empty() {
    return const LoyaltyStatus(
      deliveredOrders: 0,
      targetOrders: 10,
      currentCycleProgress: 0,
      freeDeliveriesAvailable: 0,
      hasFreeDeliveryReward: false,
      nextRewardIn: 10,
      rewardLabel: '10 pedidos entregados = 1 Delivery Gratis',
    );
  }

  factory LoyaltyStatus.fromJson(Map<String, dynamic> json) {
    final target = _asInt(json['targetOrders']) ?? 10;
    final delivered = _asInt(json['deliveredOrders']) ?? 0;
    final freeAvailable = _asInt(json['freeDeliveriesAvailable']) ?? 0;
    final hasReward = _asBool(json['hasFreeDeliveryReward']) ?? freeAvailable > 0;
    final progress = _asInt(json['currentCycleProgress']) ??
        (hasReward ? target : (target > 0 ? delivered % target : 0));
    final nextIn = _asInt(json['nextRewardIn']) ??
        (hasReward ? 0 : (target > 0 ? target - (delivered % target) : 10));

    return LoyaltyStatus(
      deliveredOrders: delivered,
      targetOrders: target,
      currentCycleProgress: progress,
      freeDeliveriesAvailable: freeAvailable,
      hasFreeDeliveryReward: hasReward,
      nextRewardIn: nextIn,
      rewardLabel: _asString(json['rewardLabel']) ??
          '10 pedidos entregados = 1 Delivery Gratis',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveredOrders': deliveredOrders,
      'targetOrders': targetOrders,
      'currentCycleProgress': currentCycleProgress,
      'freeDeliveriesAvailable': freeDeliveriesAvailable,
      'hasFreeDeliveryReward': hasFreeDeliveryReward,
      'nextRewardIn': nextRewardIn,
      'rewardLabel': rewardLabel,
    };
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
    final productMap = json['product'] is Map<String, dynamic>
        ? json['product'] as Map<String, dynamic>
        : null;
    return OrderLine(
      productId: _asString(json['productId']) ?? _asString(productMap?['id']) ?? '',
      name: _asString(json['name']) ??
          _asString(json['productName']) ??
          _asString(productMap?['name']),
      price: _asDouble(json['price'] ?? json['unitPrice'] ?? productMap?['price']),
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
    final businessMap = json['business'] is Map<String, dynamic>
        ? json['business'] as Map<String, dynamic>
        : null;

    return OrderRecord(
      id: _asString(json['id']) ?? _asString(json['orderNumber']) ?? '',
      createdAt: DateTime.tryParse(_asString(json['createdAt']) ?? '') ??
          DateTime.now(),
      items: rawItems.map(OrderLine.fromJson).toList(),
      total: _asDouble(json['total'] ?? json['grandTotal'] ?? json['totalAmount']),
      status: _asString(json['status']) ?? 'PENDING',
      deliveryEta: _asString(json['deliveryEta']) ?? '20-30 min',
      storeName: _asString(json['storeName']) ??
          _asString(json['supplierName']) ??
          _asString(businessMap?['companyName']) ??
          _asString(businessMap?['name']),
      address: _asString(json['address']) ?? _asString(json['deliveryAddress']),
      subtotal: _asNullableDouble(json['subtotal']),
      deliveryCost:
          _asNullableDouble(json['deliveryCost'] ?? json['deliveryFee']),
      discount: _asNullableDouble(json['discount'] ?? json['discountAmount']),
      paymentMethod: _asString(json['paymentMethod']),
      deliveryNote: _asString(json['deliveryNote'] ?? json['notes']),
      businessId: _asString(json['businessId']) ?? _asString(businessMap?['id']),
      supplierId: _asString(json['supplierId']) ?? _asString(json['businessId']),
    );
  }
}

String? _resolveImageUrl(Map<String, dynamic> json) {
  final direct = _asString(json['imageUrl'])?.trim();
  if (direct != null && direct.isNotEmpty) {
    return _normalizeMediaUrl(direct);
  }

  final rawImages = json['images'];
  if (rawImages is List) {
    for (final entry in rawImages) {
      if (entry is String && entry.trim().isNotEmpty) {
        return _normalizeMediaUrl(entry.trim());
      }
      if (entry is Map) {
        final url = _asString(entry['url'])?.trim();
        if (url != null && url.isNotEmpty) {
          return _normalizeMediaUrl(url);
        }
      }
    }
  } else if (rawImages is String && rawImages.trim().isNotEmpty) {
    return _normalizeMediaUrl(rawImages.trim());
  }

  return null;
}

String _normalizeMediaUrl(String raw) {
  if (raw.startsWith('/')) {
    final baseUri = Uri.tryParse(AppConfig.apiBaseUrl);
    if (baseUri != null && baseUri.hasAuthority) {
      return '${baseUri.scheme}://${baseUri.authority}$raw';
    }
    return raw;
  }
  return raw;
}

int _parseAvailableStock(Map<String, dynamic> json) {
  if (json['totalStock'] != null) {
    return _asInt(json['totalStock']) ?? 0;
  }
  if (json['availableStock'] != null) {
    return _asInt(json['availableStock']) ?? 0;
  }
  final inventory = json['inventory'];
  if (inventory is List) {
    var total = 0;
    for (final item in inventory) {
      if (item is Map) {
        total += _asInt(item['availableStock']) ??
            _asInt(item['quantity']) ??
            0;
      }
    }
    return total;
  }
  return 0;
}

List<String> _parseWarehouseNames(Map<String, dynamic> json) {
  final seen = <String>{};
  final names = <String>[];

  final direct = json['warehouseNames'];
  if (direct is List) {
    for (final item in direct) {
      final name = _asString(item)?.trim();
      if (name != null && name.isNotEmpty && seen.add(name)) {
        names.add(name);
      }
    }
    return names;
  }

  final inventory = json['inventory'];
  if (inventory is List) {
    for (final item in inventory) {
      if (item is Map) {
        final warehouse = item['warehouse'];
        final name = warehouse is Map
            ? _asString(warehouse['name'])?.trim()
            : _asString(item['warehouseName'])?.trim();
        if (name != null && name.isNotEmpty && seen.add(name)) {
          names.add(name);
        }
      }
    }
  }
  return names;
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

double? _asNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
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
    if (value.toLowerCase() == 'true') {
      return true;
    }
    if (value.toLowerCase() == 'false') {
      return false;
    }
  }
  return null;
}
