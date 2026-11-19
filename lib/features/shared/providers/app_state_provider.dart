import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/wask_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/services/geolocation_service.dart';
import '../../../core/services/loyalty_service.dart';
import '../../auth/data/auth_service.dart';
import '../../orders/data/orders_service.dart';
import '../models/app_models.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider._(
    this._prefs,
    this._tokenStorage,
    this._apiClient,
    this._authService,
    this._ordersService,
    this._loyaltyService,
  );

  final SharedPreferences _prefs;
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;
  final AuthService _authService;
  final OrdersService _ordersService;
  final LoyaltyService _loyaltyService;

  AppUser? _currentUser;
  List<DeliveryAddress> _addresses = <DeliveryAddress>[];
  String? _selectedAddressId;
  List<OrderRecord> _orders = <OrderRecord>[];
  LoyaltyStatus? _loyaltyStatus;
  String? _loyaltyBannerMessage;
  bool _isLoading = false;
  bool _isSimulatingLoyalty = false;
  String? _errorMessage;
  int _mockDeliveredBonus = 0;

  AppUser? get currentUser => _currentUser;
  List<DeliveryAddress> get addresses =>
      List<DeliveryAddress>.unmodifiable(_addresses);
  List<OrderRecord> get orders => List<OrderRecord>.unmodifiable(_orders);
  LoyaltyStatus? get loyaltyStatus => _loyaltyStatus;
  String? get loyaltyBannerMessage => _loyaltyBannerMessage;
  bool get isLoading => _isLoading;
  bool get isSimulatingLoyalty => _isSimulatingLoyalty;
  String? get errorMessage => _errorMessage;
  ApiClient get apiClient => _apiClient;
  TokenStorage get tokenStorage => _tokenStorage;
  bool get isAuthenticated => _currentUser != null;

  String get initialRoute {
    if (_currentUser == null) {
      return WaskRoutes.login;
    }
    return selectedAddress != null ? WaskRoutes.home : WaskRoutes.addressSelect;
  }

  GeoPoint get activeCustomerLocation {
    final addr = selectedAddress;
    if (addr?.latitude != null && addr?.longitude != null) {
      return GeoPoint(
        latitude: addr!.latitude!,
        longitude: addr.longitude!,
        district: addr.district,
      );
    }
    return GeolocationService.fallbackCoordinatesForDistrict(
      addr?.district ?? 'Miraflores',
    );
  }

  double? distanceToSupplierKm(Supplier supplier) {
    final customer = activeCustomerLocation;
    double? lat = supplier.latitude;
    double? lng = supplier.longitude;
    if (lat == null || lng == null) {
      final addr = (supplier.address ?? '').toLowerCase();
      for (final d in GeolocationService.limaDistricts) {
        if (addr.contains(d.name.toLowerCase())) {
          lat = d.latitude;
          lng = d.longitude;
          break;
        }
      }
    }
    if (lat == null || lng == null) {
      return null;
    }
    return GeolocationService.distanceKm(
      customer.latitude,
      customer.longitude,
      lat,
      lng,
    );
  }

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

  double calculateDeliveryFee(double subtotal) {
    if (subtotal >= 80 || (_loyaltyStatus?.hasFreeDeliveryReward == true)) {
      return 0.0;
    }
    return 7.0;
  }

  void clearLoyaltyBanner() {
    if (_loyaltyBannerMessage == null) {
      return;
    }
    _loyaltyBannerMessage = null;
    notifyListeners();
  }

  static Future<AppStateProvider> create({http.Client? httpClient}) async {
    final prefs = await SharedPreferences.getInstance();
    final tokenStorage = TokenStorage(prefs);
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      httpClient: httpClient,
    );
    final authService = AuthService(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );
    final ordersService = OrdersService(apiClient: apiClient);
    final loyaltyService = LoyaltyService(apiClient: apiClient);

    final provider = AppStateProvider._(
      prefs,
      tokenStorage,
      apiClient,
      authService,
      ordersService,
      loyaltyService,
    );
    await provider.restoreSession();
    return provider;
  }

  Future<void> restoreSession() async {
    _addresses = _loadAddresses();
    _selectedAddressId = _prefs.getString(_selectedAddressKey());
    if (_addresses.isNotEmpty && selectedAddress == null) {
      _selectedAddressId = _addresses.first.id;
      await _saveSelectedAddress();
    }

    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }
    try {
      _currentUser = await _authService.getCurrentUser();
      await _loadUserData();
      notifyListeners();
    } catch (error) {
      debugPrint('Restore session failed: $error');
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.login(email, password);
      _currentUser = await _authService.getCurrentUser();
      await _loadUserData();
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<AppUser?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );
      return user;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addAddress({
    required String label,
    required String street,
    required String district,
    String apartmentOrInterior = '',
    String intercom = '',
    String reference = '',
    String contactPhone = '',
    double? latitude,
    double? longitude,
  }) async {
    final fallback =
        GeolocationService.fallbackCoordinatesForDistrict(district);
    final newAddress = DeliveryAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label.trim().isEmpty ? 'Direccion' : label.trim(),
      street: street.trim(),
      district: district,
      apartmentOrInterior: apartmentOrInterior.trim(),
      intercom: intercom.trim(),
      reference: reference.trim(),
      contactPhone: contactPhone.trim(),
      latitude: latitude ?? fallback.latitude,
      longitude: longitude ?? fallback.longitude,
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

  Future<void> loadLoyaltyStatus() async {
    if (AppConfig.enableMocks) {
      final delivered = _orders
              .where((o) =>
                  o.status.toUpperCase() == 'DELIVERED' ||
                  o.status.toUpperCase() == 'ENTREGADO')
              .length +
          _mockDeliveredBonus;
      final used = _orders
          .where((o) =>
              o.status.toUpperCase() != 'CANCELLED' &&
              (o.deliveryNote ?? '').contains('[LOYALTY_FREE_DELIVERY]'))
          .length;
      final freeAvailable = (delivered ~/ 10) - used;
      final hasReward = freeAvailable > 0;
      _loyaltyStatus = LoyaltyStatus(
        deliveredOrders: delivered,
        targetOrders: 10,
        currentCycleProgress: hasReward ? 10 : delivered % 10,
        freeDeliveriesAvailable: freeAvailable < 0 ? 0 : freeAvailable,
        hasFreeDeliveryReward: hasReward,
        nextRewardIn: hasReward ? 0 : 10 - (delivered % 10),
        rewardLabel: '10 pedidos entregados = 1 Delivery Gratis',
      );
      notifyListeners();
      return;
    }

    try {
      _loyaltyStatus = await _loyaltyService.getLoyaltyStatus();
      notifyListeners();
    } catch (error) {
      debugPrint('Loyalty load failed: $error');
    }
  }

  Future<LoyaltyStatus?> simulateTenDeliveredOrders() async {
    _isSimulatingLoyalty = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (AppConfig.enableMocks) {
        final currentDelivered = _loyaltyStatus?.deliveredOrders ?? 0;
        final nextMultiple = ((currentDelivered ~/ 10) + 1) * 10;
        _mockDeliveredBonus += nextMultiple - currentDelivered;
        await loadLoyaltyStatus();
        _loyaltyBannerMessage =
            '¡Felicidades! 10 pedidos entregados = 1 Delivery Gratis desbloqueado';
        notifyListeners();
        return _loyaltyStatus;
      }

      final updated = await _loyaltyService.simulateTenDeliveredOrders();
      _loyaltyStatus = updated;
      _loyaltyBannerMessage =
          '¡Felicidades! 10 pedidos entregados = 1 Delivery Gratis desbloqueado';
      notifyListeners();
      return updated;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return null;
    } finally {
      _isSimulatingLoyalty = false;
      notifyListeners();
    }
  }

  Future<OrderRecord?> placeOrder({
    required List<OrderLine> items,
    required String storeName,
    required String paymentMethod,
    required double subtotal,
    required double deliveryCost,
    required double discount,
    required String deliveryNote,
    required String businessId,
    bool applyLoyaltyReward = false,
  }) async {
    if (_currentUser == null || selectedAddress == null || items.isEmpty) {
      return null;
    }

    if (AppConfig.enableMocks) {
      final total = subtotal + deliveryCost - discount;
      final noteWithReward = applyLoyaltyReward
          ? '${deliveryNote.trim()} [LOYALTY_FREE_DELIVERY]'.trim()
          : deliveryNote;
      final order = OrderRecord(
        id: 'WK-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        createdAt: DateTime.now(),
        deliveryEta: '25-30 min',
        storeName: storeName,
        address: selectedAddress!.formattedFullAddress,
        items: items,
        subtotal: subtotal,
        deliveryCost: deliveryCost,
        discount: discount,
        total: total,
        paymentMethod: paymentMethod,
        status: 'EN_CAMINO',
        deliveryNote: noteWithReward,
        businessId: businessId,
        supplierId: businessId,
      );
      _orders = <OrderRecord>[order, ..._orders];
      await _saveOrders();
      await loadLoyaltyStatus();
      notifyListeners();
      return order;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      final order = await _ordersService.createOrder(
        businessId: businessId,
        items: items,
        notes: deliveryNote,
        deliveryAddress: selectedAddress!.formattedFullAddress,
        paymentMethod: paymentMethod,
        applyLoyaltyReward: applyLoyaltyReward,
      );
      await loadLoyaltyStatus();
      return order;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _addresses = <DeliveryAddress>[];
    _selectedAddressId = null;
    _orders = <OrderRecord>[];
    _loyaltyStatus = null;
    _loyaltyBannerMessage = null;
    notifyListeners();
  }

  Future<void> loadOrders() async {
    if (AppConfig.enableMocks) {
      _orders = _loadOrders();
      notifyListeners();
      return;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      _orders = await _ordersService.getOrders();
      notifyListeners();
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadUserData() async {
    _addresses = _loadAddresses();
    _selectedAddressId = _prefs.getString(_selectedAddressKey());
    if (AppConfig.enableMocks) {
      _orders = _loadOrders();
    } else {
      _orders = <OrderRecord>[];
    }

    if (_addresses.isNotEmpty && selectedAddress == null) {
      _selectedAddressId = _addresses.first.id;
      await _saveSelectedAddress();
    }

    await loadLoyaltyStatus();
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Tu sesion expiro. Inicia sesion nuevamente.';
      }
      if (error.statusCode == 403) {
        return 'No tienes permisos para esta accion.';
      }
      if (error.statusCode == 404) {
        return 'Recurso no encontrado.';
      }
      if (error.statusCode != null && error.statusCode! >= 500) {
        return 'El servidor tuvo un problema. Intenta luego.';
      }
      return error.message;
    }
    return 'Ocurrio un error inesperado.';
  }
}
