import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider._(this._prefs);

  final SharedPreferences _prefs;

  static const String _usersKey = 'wask_users';

  AppUser? _currentUser;
  List<DeliveryAddress> _addresses = <DeliveryAddress>[];
  String? _selectedAddressId;
  List<OrderRecord> _orders = <OrderRecord>[];

  AppUser? get currentUser => _currentUser;
  List<DeliveryAddress> get addresses =>
      List<DeliveryAddress>.unmodifiable(_addresses);
  List<OrderRecord> get orders => List<OrderRecord>.unmodifiable(_orders);

  DeliveryAddress? get selectedAddress {
    if (_selectedAddressId == null) {
      return null;
    }
    for (final address in _addresses) {
      if (address.id == _selectedAddressId) {
        return address;
      }
    }
    return null;
  }

  String get displayName {
    final fullName = _currentUser?.name.trim() ?? '';
    if (fullName.isEmpty) {
      return 'Invitado';
    }

    return fullName.split(RegExp(r'\s+')).first;
  }

  static Future<AppStateProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AppStateProvider._(prefs);
  }

  Future<void> signIn({required String email, String? nameHint}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final usersMap = _loadUsers();

    if (!usersMap.containsKey(normalizedEmail)) {
      usersMap[normalizedEmail] = (nameHint?.trim().isNotEmpty ?? false)
          ? nameHint!.trim()
          : _nameFromEmail(normalizedEmail);
      await _prefs.setString(_usersKey, jsonEncode(usersMap));
    }

    _currentUser = AppUser(
      name: usersMap[normalizedEmail] ?? _nameFromEmail(normalizedEmail),
      email: normalizedEmail,
    );

    await _loadUserData();
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final usersMap = _loadUsers();
    usersMap[normalizedEmail] =
        name.trim().isEmpty ? _nameFromEmail(normalizedEmail) : name.trim();
    await _prefs.setString(_usersKey, jsonEncode(usersMap));

    _currentUser = AppUser(
      name: usersMap[normalizedEmail]!,
      email: normalizedEmail,
    );

    await _loadUserData();
    notifyListeners();
  }

  Future<void> addAddress({
    required String label,
    required String street,
    required String district,
    String reference = '',
  }) async {
    if (_currentUser == null) {
      return;
    }

    final newAddress = DeliveryAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label.trim().isEmpty ? 'Direccion' : label.trim(),
      street: street.trim(),
      district: district,
      reference: reference.trim(),
    );

    _addresses = <DeliveryAddress>[newAddress, ..._addresses];
    _selectedAddressId = newAddress.id;
    await _saveAddresses();
    notifyListeners();
  }

  Future<void> selectAddress(String addressId) async {
    _selectedAddressId = addressId;
    await _saveSelectedAddress();
    notifyListeners();
  }

  Future<void> placeOrder({
    required List<OrderLine> items,
    required String storeName,
    required String paymentMethod,
    required double subtotal,
    required double deliveryCost,
    required double discount,
    required String deliveryNote,
  }) async {
    if (_currentUser == null || selectedAddress == null || items.isEmpty) {
      return;
    }

    final total = subtotal + deliveryCost - discount;
    final order = OrderRecord(
      id: 'WK-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      createdAt: DateTime.now(),
      deliveryEta: '25-30 min',
      storeName: storeName,
      address: selectedAddress!.formatted,
      items: items,
      subtotal: subtotal,
      deliveryCost: deliveryCost,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      status: 'En camino',
      deliveryNote: deliveryNote,
    );

    _orders = <OrderRecord>[order, ..._orders];
    await _saveOrders();
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _addresses = <DeliveryAddress>[];
    _selectedAddressId = null;
    _orders = <OrderRecord>[];
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    _addresses = _loadAddresses();
    _selectedAddressId = _prefs.getString(_selectedAddressKey());
    _orders = _loadOrders();

    if (_addresses.isNotEmpty && selectedAddress == null) {
      _selectedAddressId = _addresses.first.id;
      await _saveSelectedAddress();
    }
  }

  Map<String, String> _loadUsers() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return <String, String>{};
    }

    return decoded.map((key, value) => MapEntry(key, '$value'));
  }

  List<DeliveryAddress> _loadAddresses() {
    final raw = _prefs.getString(_addressesKey());
    if (raw == null || raw.isEmpty) {
      return <DeliveryAddress>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return <DeliveryAddress>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(DeliveryAddress.fromJson)
        .toList();
  }

  List<OrderRecord> _loadOrders() {
    final raw = _prefs.getString(_ordersKey());
    if (raw == null || raw.isEmpty) {
      return <OrderRecord>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return <OrderRecord>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(OrderRecord.fromJson)
        .toList();
  }

  Future<void> _saveAddresses() async {
    final encoded = jsonEncode(_addresses.map((a) => a.toJson()).toList());
    await _prefs.setString(_addressesKey(), encoded);
    await _saveSelectedAddress();
  }

  Future<void> _saveSelectedAddress() async {
    if (_selectedAddressId == null) {
      await _prefs.remove(_selectedAddressKey());
      return;
    }
    await _prefs.setString(_selectedAddressKey(), _selectedAddressId!);
  }

  Future<void> _saveOrders() async {
    final encoded = jsonEncode(_orders.map((o) => o.toJson()).toList());
    await _prefs.setString(_ordersKey(), encoded);
  }

  String _addressesKey() => 'wask_addresses_${_currentUser?.email ?? ''}';

  String _selectedAddressKey() =>
      'wask_selected_address_${_currentUser?.email ?? ''}';

  String _ordersKey() => 'wask_orders_${_currentUser?.email ?? ''}';

  String _nameFromEmail(String email) {
    final base = email.split('@').first;
    if (base.isEmpty) {
      return 'Usuario';
    }
    final normalized = base.replaceAll('.', ' ').replaceAll('_', ' ').trim();
    if (normalized.isEmpty) {
      return 'Usuario';
    }
    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
