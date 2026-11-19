import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wask_app/core/navigation/wask_routes.dart';
import 'package:wask_app/core/services/geolocation_service.dart';
import 'package:wask_app/core/theme/wask_theme.dart';
import 'package:wask_app/features/address/screens/address_selection_screen.dart';
import 'package:wask_app/features/auth/screens/login_screen.dart';
import 'package:wask_app/features/cart/screens/cart_screen.dart';
import 'package:wask_app/features/checkout/screens/checkout_screen.dart';
import 'package:wask_app/features/home/screens/home_screen.dart';
import 'package:wask_app/features/orders/screens/orders_screen.dart';
import 'package:wask_app/features/search/screens/search_screen.dart';
import 'package:wask_app/features/shared/models/app_models.dart';
import 'package:wask_app/features/shared/providers/app_state_provider.dart';
import 'package:wask_app/features/shared/widgets/wask_bottom_nav.dart';
import 'package:wask_app/features/shop/providers/cart_provider.dart';
import 'package:wask_app/features/shop/screens/product_detail_screen.dart';
import 'package:wask_app/features/tracking/providers/tracking_provider.dart';
import 'package:wask_app/features/tracking/screens/tracking_screen.dart';
import 'package:wask_app/main.dart';

Map<String, dynamic> _envelope(dynamic data) => <String, dynamic>{
      'success': true,
      'data': data,
      'timestamp': '2026-11-18T12:00:00.000Z',
    };

MockClient _buildApiMockClient({
  void Function(Map<String, dynamic> body)? onOrderPost,
  bool loyaltyUnlocked = false,
}) {
  var simulated = loyaltyUnlocked;
  return MockClient((request) async {
    final path = request.url.path;

    if (path.endsWith('/auth/login') && request.method == 'POST') {
      return http.Response(
        jsonEncode(_envelope({
          'accessToken': 'demo-jwt',
          'refreshToken': 'demo-refresh',
        })),
        200,
      );
    }

    if (path.endsWith('/users/me')) {
      return http.Response(
        jsonEncode(_envelope({
          'id': 'cust-1',
          'firstName': 'Marco',
          'lastName': 'Quispe',
          'email': 'customer@wask.io',
          'role': 'CUSTOMER',
          'status': 'ACTIVE',
          'isVerified': true,
        })),
        200,
      );
    }

    if (path.endsWith('/orders/loyalty/simulate') &&
        request.method == 'POST') {
      simulated = true;
      return http.Response(
        jsonEncode(_envelope({
          'deliveredOrders': 10,
          'targetOrders': 10,
          'currentCycleProgress': 10,
          'freeDeliveriesAvailable': 1,
          'hasFreeDeliveryReward': true,
          'nextRewardIn': 0,
          'rewardLabel': '10 pedidos entregados = 1 Delivery Gratis',
        })),
        200,
      );
    }

    if (path.endsWith('/orders/loyalty')) {
      return http.Response(
        jsonEncode(_envelope({
          'deliveredOrders': simulated ? 10 : 3,
          'targetOrders': 10,
          'currentCycleProgress': simulated ? 10 : 3,
          'freeDeliveriesAvailable': simulated ? 1 : 0,
          'hasFreeDeliveryReward': simulated,
          'nextRewardIn': simulated ? 0 : 7,
          'rewardLabel': '10 pedidos entregados = 1 Delivery Gratis',
        })),
        200,
      );
    }

    if (path.endsWith('/business/shops')) {
      return http.Response(
        jsonEncode(_envelope([
          {
            'id': 'biz-1',
            'companyName': 'Licoreria Demo Wask',
            'address': 'Av. Larco 123, Miraflores, Lima',
            'phone': '+51 1 234 5678',
            'latitude': -12.1211,
            'longitude': -77.0293,
            'operationalStatus': 'ACTIVE',
          },
          {
            'id': 'biz-2',
            'companyName': 'Licoreria El Tambo Peruano',
            'address': 'Av. Javier Prado Este 890, San Isidro',
            'phone': '+51 1 442 8890',
            'latitude': -12.0910,
            'longitude': -77.0226,
            'operationalStatus': 'ACTIVE',
          },
        ])),
        200,
      );
    }

    if (path.endsWith('/products')) {
      final q = (request.url.queryParameters['q'] ?? '').toLowerCase();
      final all = [
        {
          'id': 'prod-1',
          'sku': 'PILSEN-630',
          'name': 'Cerveza Pilsen 630ml',
          'category': 'Cerveza',
          'brand': 'Pilsen Callao',
          'volumeMl': 630,
          'price': 5.5,
          'businessId': 'biz-1',
          'images': ['http://localhost:3000/uploads/pilsen-630.png'],
          'totalStock': 40,
          'business': {'id': 'biz-1', 'companyName': 'Licoreria Demo Wask'},
          'inventory': [
            {
              'availableStock': 40,
              'warehouse': {'name': 'Almacen Central Demo'},
            },
          ],
        },
        {
          'id': 'prod-2',
          'sku': 'PISCO-750',
          'name': 'Pisco Quebranta 750ml',
          'category': 'Pisco',
          'brand': 'Tabernero',
          'volumeMl': 750,
          'price': 45.0,
          'businessId': 'biz-2',
          'images': ['http://localhost:3000/uploads/pisco-quebranta.png'],
          'totalStock': 4,
          'business': {
            'id': 'biz-2',
            'companyName': 'Licoreria El Tambo Peruano',
          },
          'inventory': [
            {
              'availableStock': 4,
              'warehouse': {'name': 'Almacen San Isidro'},
            },
          ],
        },
      ];
      final filtered = q.isEmpty
          ? all
          : all
              .where((p) => (p['name'] as String).toLowerCase().contains(q))
              .toList();
      return http.Response(jsonEncode(_envelope(filtered)), 200);
    }

    if (path.endsWith('/orders') && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      onOrderPost?.call(body);
      return http.Response(
        jsonEncode(_envelope({
          'id': 'order-99',
          'status': 'PENDING',
          'total': 5.5,
          'businessId': body['businessId'],
          'deliveryAddress': body['deliveryAddress'],
          'paymentMethod': body['paymentMethod'],
          'items': body['items'],
          'createdAt': '2026-11-18T12:05:00.000Z',
        })),
        201,
      );
    }

    if (path.endsWith('/orders')) {
      return http.Response(
        jsonEncode(_envelope([
          {
            'id': 'order-prev-1',
            'status': 'DELIVERED',
            'total': 11.0,
            'businessId': 'biz-1',
            'storeName': 'Licoreria Demo Wask',
            'deliveryAddress': 'Av. Larco 450 · Miraflores',
            'items': [
              {
                'productId': 'prod-1',
                'name': 'Cerveza Pilsen 630ml',
                'price': 5.5,
                'quantity': 2,
              },
            ],
            'createdAt': '2026-11-17T22:00:00.000Z',
          },
        ])),
        200,
      );
    }

    return http.Response(jsonEncode(_envelope({})), 200);
  });
}

Widget _wrapWithProviders({
  required AppStateProvider appState,
  required Widget child,
  CartProvider? cartProvider,
  TrackingProvider? trackingProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppStateProvider>.value(value: appState),
      ChangeNotifierProvider<CartProvider>(
        create: (_) => cartProvider ?? CartProvider(),
      ),
      ChangeNotifierProvider<TrackingProvider>(
        create: (_) => trackingProvider ?? TrackingProvider(),
      ),
    ],
    child: MaterialApp(
      theme: WaskTheme.darkTheme,
      home: child,
      routes: {
        WaskRoutes.home: (_) => const HomeScreen(),
        WaskRoutes.search: (_) => const SearchScreen(),
        WaskRoutes.addressSelect: (_) => const AddressSelectionScreen(),
        WaskRoutes.tracking: (_) => const TrackingScreen(),
        WaskRoutes.cart: (_) => const CartScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == WaskRoutes.productDetail) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute<void>(
            builder: (_) => ProductDetailScreen(
              productId: (args?['id'] ?? 'prod-1') as String,
              productName: (args?['name'] ?? 'Producto') as String,
              price: ((args?['price'] ?? 0) as num).toDouble(),
              supplierId: args?['supplierId'] as String?,
              availableStock: args?['availableStock'] as int?,
              storeName: args?['storeName'] as String?,
            ),
          );
        }
        return null;
      },
    ),
  );
}

void main() {
  test('Models and GeolocationService compute Haversine distance and districts',
      () {
    final product = Product.fromJson({
      'id': 'p1',
      'name': 'Cerveza Cusquena Trigo 620ml',
      'price': '7.20',
      'businessId': 'b1',
      'images': ['http://localhost:3000/uploads/cusquena-trigo.png'],
      'business': {'id': 'b1', 'companyName': 'Licoreria Demo Wask'},
      'inventory': [
        {
          'availableStock': 12,
          'warehouse': {'name': 'Almacen Central'},
        },
      ],
    });
    expect(product.imageUrl, 'http://localhost:3000/uploads/cusquena-trigo.png');
    expect(product.availableStock, 12);

    const address = DeliveryAddress(
      id: 'a1',
      label: 'Reunión',
      street: 'Av. Arequipa 1950',
      district: 'Lince',
      apartmentOrInterior: 'Dpto 501',
      intercom: '501',
      reference: 'Frente a parque',
      contactPhone: '999888777',
      latitude: -12.0845,
      longitude: -77.0352,
    );
    expect(address.latitude, -12.0845);
    expect(address.longitude, -77.0352);

    // Miraflores -> San Isidro (~3.4 km)
    final dist = GeolocationService.distanceKm(
      -12.1211,
      -77.0293,
      -12.0910,
      -77.0226,
    );
    expect(dist, greaterThan(3.0));
    expect(dist, lessThan(4.0));
    expect(GeolocationService.inferLimaDistrict(-12.0910, -77.0226),
        'San Isidro');
  });

  testWidgets('WaskApp jumps directly to Home when authenticated with address',
      (WidgetTester tester) async {
    final savedAddress = jsonEncode([
      {
        'id': 'addr-1',
        'label': 'Casa',
        'street': 'Av. Larco 450',
        'district': 'Miraflores',
        'latitude': -12.1211,
        'longitude': -77.0293,
      },
    ]);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'wask_access_token': 'demo-jwt',
      'wask_addresses_customer@wask.io': savedAddress,
      'wask_selected_address_customer@wask.io': 'addr-1',
    });

    final appStateProvider = await AppStateProvider.create(
      httpClient: _buildApiMockClient(),
    );
    expect(appStateProvider.initialRoute, WaskRoutes.home);

    await tester.pumpWidget(WaskApp(appStateProvider: appStateProvider));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Marco'), findsOneWidget);
    expect(find.text('INICIAR SESION'), findsNothing);
  });

  testWidgets('Login navigates straight to Home if user already has saved address',
      (WidgetTester tester) async {
    final savedAddress = jsonEncode([
      {
        'id': 'addr-1',
        'label': 'Casa',
        'street': 'Av. Larco 450',
        'district': 'Miraflores',
      },
    ]);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'wask_addresses_customer@wask.io': savedAddress,
      'wask_selected_address_customer@wask.io': 'addr-1',
    });
    final appState = await AppStateProvider.create(
      httpClient: _buildApiMockClient(),
    );

    await tester.pumpWidget(
      _wrapWithProviders(appState: appState, child: const LoginScreen()),
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Correo electronico'),
      'customer@wask.io',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Contrasena'),
      'ChangeMe123!',
    );
    await tester.tap(find.text('Verificar edad (+18)'));
    await tester.pump();
    await tester.tap(find.text('INICIAR SESION'));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Marco'), findsOneWidget);
  });

  testWidgets('WaskBottomNav fits at ~56px without overflow on narrow 320px',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final appState = await AppStateProvider.create();

    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrapWithProviders(
        appState: appState,
        child: const Scaffold(
          bottomNavigationBar: WaskBottomNav(currentRoute: WaskRoutes.home),
          body: SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.height, 56);
    expect(navBar.labelBehavior, NavigationDestinationLabelBehavior.alwaysShow);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'HomeScreen enforces strict privacy, sorts stores by distance, and guards multi-store cart',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'wask_access_token': 'demo-jwt',
    });
    final appState = await AppStateProvider.create(
      httpClient: _buildApiMockClient(),
    );
    // Cliente ubicado en San Isidro -> Licoreria El Tambo Peruano debe salir primero!
    await appState.addAddress(
      label: 'Oficina',
      street: 'Av. Javier Prado 800',
      district: 'San Isidro',
      latitude: -12.0910,
      longitude: -77.0226,
    );

    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrapWithProviders(appState: appState, child: const HomeScreen()),
    );
    await tester.pumpAndSettle();

    // Privacidad estricta: cero Stock:, cero telefonos de proveedor, cero nombres de almacen
    expect(find.textContaining('Stock:'), findsNothing);
    expect(find.textContaining('+51 1 234 5678'), findsNothing);
    expect(find.textContaining('Almacen Central Demo'), findsNothing);
    expect(find.textContaining('Sucursales'), findsNothing);

    // Badges amigables + distancia real
    expect(find.text('Disponible'), findsWidgets);
    expect(find.text('Pocas unidades'), findsWidgets);
    expect(find.textContaining('Cerca de ti'), findsWidgets);

    // Ordenado por cercania: El Tambo (0.0 km) aparece antes que Demo Wask (~3.4 km)
    final tamboY =
        tester.getTopLeft(find.text('Licoreria El Tambo Peruano').first).dy;
    final demoY =
        tester.getTopLeft(find.text('Licoreria Demo Wask').first).dy;
    expect(tamboY, lessThan(demoY));

    // Modal de tienda sin telefono ni almacen
    await tester.tap(find.text('Licoreria Demo Wask').first);
    await tester.pumpAndSettle();
    expect(find.text('Verificada'), findsOneWidget);
    expect(find.textContaining('Tel:'), findsNothing);
    expect(find.textContaining('Almacen Central Demo'), findsNothing);

    await tester.tap(find.text('+ Agregar').first);
    await tester.pumpAndSettle();
    expect(find.text('En carrito: 1'), findsOneWidget);
    expect(find.textContaining('Ir al carrito (1)'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Intentar agregar de otra tienda (Pisco de biz-2) muestra dialogo de cambio de tienda
    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('¿Cambiar de tienda?'), findsOneWidget);
    await tester.tap(find.text('Cambiar tienda'));
    await tester.pumpAndSettle();
    expect(find.text('Ver carrito'), findsWidgets);
  });

  testWidgets('SearchScreen hides numeric stock and shows availability pill',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'wask_access_token': 'demo-jwt',
    });
    final appState = await AppStateProvider.create(
      httpClient: _buildApiMockClient(),
    );

    await tester.pumpWidget(
      _wrapWithProviders(appState: appState, child: const SearchScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Stock:'), findsNothing);
    expect(find.text('Disponible'), findsWidgets);
    expect(find.text('Pocas unidades'), findsWidgets);
  });

  testWidgets('Rappi 3-step AddressSelectionScreen uses GPS, OSM map, and saves lat/lng',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final appState = await AppStateProvider.create();
    final mockGeo = GeolocationService(
      fetcher: () async => (latitude: -12.1211, longitude: -77.0293),
    );

    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrapWithProviders(
        appState: appState,
        child: AddressSelectionScreen(geolocationService: mockGeo),
      ),
    );
    await tester.pumpAndSettle();

    // Paso 1
    expect(find.text('¿A dónde llevamos tu pedido?'), findsWidgets);
    await tester.tap(find.text('Usar mi ubicación actual (GPS)'));
    await tester.pumpAndSettle();

    // Paso 2 (Verifica tu ubicacion en mapa OSM)
    expect(find.text('Verifica tu ubicación'), findsOneWidget);
    expect(find.textContaining('© OpenStreetMap'), findsOneWidget);
    expect(find.textContaining('tiendas cerca de aquí'), findsOneWidget);
    await tester.tap(find.text('Confirmar ubicación'));
    await tester.pumpAndSettle();

    // Paso 3 (Detalles para el motorizado)
    expect(find.text('Detalles para el motorizado'), findsOneWidget);
    expect(find.text('Reunión'), findsOneWidget);
    await tester.tap(find.text('Reunión'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Piso / Dpto / Interior (opcional)'),
      'Dpto 402',
    );
    await tester.tap(find.text('Guardar dirección y ver tiendas'));
    await tester.pumpAndSettle();

    expect(appState.selectedAddress, isNotNull);
    expect(appState.selectedAddress!.label, 'Reunión');
    expect(appState.selectedAddress!.district, 'Miraflores');
    expect(appState.selectedAddress!.latitude, closeTo(-12.1211, 0.001));
  });

  testWidgets('CheckoutScreen shows Yape/Plin wallet card, +18 switch, and strict DTO',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'wask_access_token': 'demo-jwt',
    });
    Map<String, dynamic>? capturedOrderBody;
    final mockClient = _buildApiMockClient(
      loyaltyUnlocked: true,
      onOrderPost: (body) => capturedOrderBody = body,
    );
    final appState = await AppStateProvider.create(httpClient: mockClient);

    await appState.addAddress(
      label: 'Casa',
      street: 'Av. Larco 450',
      district: 'Miraflores',
      reference: 'Frente al parque',
      contactPhone: '999888777',
    );

    final cart = CartProvider();
    cart.addItem(
      productId: 'prod-1',
      name: 'Cerveza Pilsen 630ml',
      price: 5.5,
      quantity: 2,
      supplierId: 'biz-1',
      storeName: 'Licoreria Demo Wask',
    );

    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(value: appState),
          ChangeNotifierProvider<CartProvider>.value(value: cart),
          ChangeNotifierProvider<TrackingProvider>(
            create: (_) => TrackingProvider(),
          ),
        ],
        child: MaterialApp(
          theme: WaskTheme.darkTheme,
          home: const CheckoutScreen(deliveryInstruction: 'Tocar timbre'),
          routes: {
            WaskRoutes.orders: (_) => const Scaffold(body: Text('Pedidos OK')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('999 888 777'), findsOneWidget);
    expect(find.text('Confirmo tener +18 años al recibir el pedido'),
        findsOneWidget);
    expect(
      find.text('Delivery Gratis (Fidelizacion 10 pedidos)'),
      findsOneWidget,
    );
    expect(find.text('S/ -0.00'), findsNothing);

    await tester.tap(find.text('Plin'));
    await tester.pump();
    await tester.tap(find.text('Confirmar y pagar con Plin'));
    await tester.pumpAndSettle();

    expect(capturedOrderBody, isNotNull);
    expect(capturedOrderBody!['businessId'], 'biz-1');
    expect(capturedOrderBody!['paymentMethod'], 'Plin');
    expect(capturedOrderBody!['applyLoyaltyReward'], isTrue);
  });

  testWidgets('OrdersScreen Volver a pedir reloads items into Cart',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'wask_access_token': 'demo-jwt',
    });
    final appState = await AppStateProvider.create(
      httpClient: _buildApiMockClient(),
    );
    final cart = CartProvider();

    await tester.pumpWidget(
      _wrapWithProviders(
        appState: appState,
        cartProvider: cart,
        child: const OrdersScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Volver a pedir'), findsOneWidget);
    await tester.tap(find.text('Volver a pedir'));
    await tester.pumpAndSettle();

    expect(cart.totalItems, 2);
    expect(find.text('Cerveza Pilsen 630ml'), findsOneWidget);
  });

  testWidgets('TrackingScreen renders OpenStreetMap without /logistics/shipments',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    var calledLogisticsShipments = false;
    final guardClient = MockClient((request) async {
      if (request.url.path.contains('/logistics/shipments')) {
        calledLogisticsShipments = true;
      }
      return http.Response(jsonEncode(_envelope({})), 200);
    });
    final appState = await AppStateProvider.create(httpClient: guardClient);

    await tester.pumpWidget(
      _wrapWithProviders(appState: appState, child: const TrackingScreen()),
    );
    await tester.pump();

    expect(calledLogisticsShipments, isFalse);
    expect(find.textContaining('© OpenStreetMap'), findsOneWidget);
    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(find.text('Simular avance de motorizado'), findsOneWidget);

    await tester.tap(find.text('Simular avance de motorizado'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  test('Supplier pilot fields parse isOpenNow, radius, and wallet numbers', () {
    final pausedShop = Supplier.fromJson({
      'id': 'shop-paused',
      'companyName': 'Licoreria Cerrada',
      'operationalStatus': 'PAUSED',
      'openTime': '18:00',
      'closeTime': '03:00',
      'deliveryRadiusKm': 5,
      'yapeNumber': '911 222 333',
      'plinNumber': '944 555 666',
    });

    expect(pausedShop.isOpenNow, isFalse);
    expect(pausedShop.openTime, '18:00');
    expect(pausedShop.closeTime, '03:00');
    expect(pausedShop.deliveryRadiusKm, 5.0);
    expect(pausedShop.yapeNumber, '911 222 333');
    expect(pausedShop.plinNumber, '944 555 666');
    expect(pausedShop.canDeliverDistance(4.9), isTrue);
    expect(pausedShop.canDeliverDistance(5.1), isFalse);
  });

  test('TrackingProvider syncWithOrder maps backend statuses accurately', () {
    final provider = TrackingProvider();

    OrderRecord makeOrder(String status) => OrderRecord(
          id: 'ord-99',
          items: const <OrderLine>[],
          total: 42.0,
          subtotal: 37.0,
          deliveryCost: 5.0,
          discount: 0.0,
          status: status,
          paymentMethod: 'Yape',
          address: 'Av. Larco 450 · Miraflores',
          storeName: 'Licoreria Demo Wask',
          createdAt: DateTime(2026, 11, 18, 20, 0),
        );

    provider.syncWithOrder(makeOrder('PENDING'));
    expect(provider.currentStepIndex, 0);
    expect(provider.isCancelled, isFalse);

    provider.syncWithOrder(makeOrder('PROCESSING'));
    expect(provider.currentStepIndex, 1);
    expect(provider.currentStatusLabel, 'Preparando tu pedido en tienda');

    provider.syncWithOrder(makeOrder('SHIPPED'));
    expect(provider.currentStepIndex, 2);
    expect(provider.currentStatusLabel, 'Motorizado en camino');

    provider.syncWithOrder(makeOrder('DELIVERED'));
    expect(provider.currentStepIndex, 3);
    expect(provider.isDelivered, isTrue);

    provider.syncWithOrder(makeOrder('CANCELLED'));
    expect(provider.isCancelled, isTrue);
    expect(provider.currentStatusLabel, 'Pedido cancelado');
  });

  testWidgets('LoginScreen opens password recovery sheet and submits flow',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    String? forgotEmailSent;
    Map<String, dynamic>? resetPayload;

    final recoveryClient = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/auth/forgot-password') && request.method == 'POST') {
        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        forgotEmailSent = decoded['email'] as String?;
        return http.Response(
          jsonEncode(_envelope({'message': 'Codigo enviado'})),
          200,
        );
      }
      if (path.endsWith('/auth/reset-password') && request.method == 'POST') {
        resetPayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(_envelope({'message': 'Contrasena actualizada'})),
          200,
        );
      }
      return http.Response(jsonEncode(_envelope({})), 200);
    });

    final appState = await AppStateProvider.create(httpClient: recoveryClient);

    await tester.pumpWidget(
      _wrapWithProviders(appState: appState, child: const LoginScreen()),
    );
    await tester.pump();

    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Tu correo electronico'),
      'piloto@wask.io',
    );
    await tester.tap(find.text('Solicitar codigo'));
    await tester.pumpAndSettle();

    expect(forgotEmailSent, 'piloto@wask.io');
    expect(find.text('Guardar nueva contrasena'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Codigo de recuperacion'),
      'TOKEN-1234',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Nueva contrasena (min. 10 caracteres)'),
      'NuevaClave2026!',
    );
    await tester.tap(find.text('Guardar nueva contrasena'));
    await tester.pumpAndSettle();

    expect(resetPayload, isNotNull);
    expect(resetPayload!['token'], 'TOKEN-1234');
    expect(resetPayload!['password'], 'NuevaClave2026!');
  });

  testWidgets(
      'CheckoutScreen loads store wallet numbers and attaches op code + Factura RUC note',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'wask_access_token': 'demo-jwt',
    });
    Map<String, dynamic>? capturedOrderBody;

    final pilotClient = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/users/me')) {
        return http.Response(
          jsonEncode(_envelope({
            'id': 'cust-1',
            'firstName': 'Marco',
            'lastName': 'Quispe',
            'email': 'customer@wask.io',
            'role': 'CUSTOMER',
            'status': 'ACTIVE',
            'isVerified': true,
          })),
          200,
        );
      }
      if (path.endsWith('/orders/loyalty')) {
        return http.Response(
          jsonEncode(_envelope({
            'deliveredOrders': 1,
            'targetOrders': 10,
            'currentCycleProgress': 1,
            'freeDeliveriesAvailable': 0,
            'hasFreeDeliveryReward': false,
            'nextRewardIn': 9,
            'rewardLabel': '10 pedidos entregados = 1 Delivery Gratis',
          })),
          200,
        );
      }
      if (path.endsWith('/business/shops')) {
        return http.Response(
          jsonEncode(_envelope([
            {
              'id': 'biz-1',
              'companyName': 'Licoreria Demo Wask',
              'address': 'Av. Larco 123, Miraflores, Lima',
              'operationalStatus': 'ACTIVE',
              'isOpenNow': true,
              'yapeNumber': '911 222 333',
              'plinNumber': '944 555 666',
              'deliveryRadiusKm': 8,
            },
          ])),
          200,
        );
      }
      if (path.endsWith('/orders') && request.method == 'POST') {
        capturedOrderBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(_envelope({
            'id': 'order-pilot-1',
            'status': 'PENDING',
            'total': 16.0,
            'businessId': 'biz-1',
            'deliveryAddress': capturedOrderBody!['deliveryAddress'],
            'notes': capturedOrderBody!['notes'],
            'paymentMethod': capturedOrderBody!['paymentMethod'],
            'items': capturedOrderBody!['items'],
            'createdAt': '2026-11-18T12:15:00.000Z',
          })),
          201,
        );
      }
      if (path.endsWith('/orders')) {
        return http.Response(jsonEncode(_envelope([])), 200);
      }
      return http.Response(jsonEncode(_envelope({})), 200);
    });

    final appState = await AppStateProvider.create(httpClient: pilotClient);
    await appState.addAddress(
      label: 'Casa',
      street: 'Av. Larco 450',
      district: 'Miraflores',
      reference: 'Puerta negra',
      contactPhone: '999111222',
    );

    final cart = CartProvider();
    cart.addItem(
      productId: 'prod-1',
      name: 'Cerveza Pilsen 630ml',
      price: 5.5,
      quantity: 2,
      supplierId: 'biz-1',
      storeName: 'Licoreria Demo Wask',
    );

    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(value: appState),
          ChangeNotifierProvider<CartProvider>.value(value: cart),
          ChangeNotifierProvider<TrackingProvider>(
            create: (_) => TrackingProvider(),
          ),
        ],
        child: MaterialApp(
          theme: WaskTheme.darkTheme,
          home: const CheckoutScreen(deliveryInstruction: 'Llamar al llegar'),
          routes: {
            WaskRoutes.orders: (_) => const Scaffold(body: Text('Pedidos OK')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Yape · 911 222 333'), findsOneWidget);
    expect(find.text('Boleta simple'), findsOneWidget);
    expect(find.text('Factura (RUC)'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(
        TextField,
        'N° operacion o nombre quien paga (opcional)',
      ),
      'OP-778899',
    );
    await tester.tap(find.text('Factura (RUC)'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextField, 'Ingresa tu RUC (11 digitos)'),
      '12345',
    );
    await tester.tap(find.text('Confirmar y pagar con Yape'));
    await tester.pumpAndSettle();
    expect(capturedOrderBody, isNull);
    expect(find.textContaining('11 digitos numericos'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Ingresa tu RUC (11 digitos)'),
      '20601234561',
    );
    await tester.tap(find.text('Confirmar y pagar con Yape'));
    await tester.pumpAndSettle();

    expect(capturedOrderBody, isNotNull);
    expect(
      capturedOrderBody!['notes'],
      contains('[Pago Op: OP-778899]'),
    );
    expect(
      capturedOrderBody!['notes'],
      contains('[Comprobante: Factura (RUC) - 20601234561]'),
    );
  });

  testWidgets('TrackingScreen with initialOrder hides demo buttons and shows Actualizar estado ahora',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final appState = await AppStateProvider.create();
    await appState.addAddress(
      label: 'Casa',
      street: 'Av. Larco 450',
      district: 'Miraflores',
    );

    final realOrder = OrderRecord(
      id: 'ord-real-1',
      createdAt: DateTime(2026, 11, 18, 21, 0),
      items: const [
        OrderLine(productId: 'prod-1', quantity: 2, name: 'Pilsen', price: 5.5),
      ],
      total: 18.0,
      status: 'SHIPPED',
      storeName: 'Licoreria Demo Wask',
      address: 'Av. Larco 450 · Miraflores',
    );

    await tester.pumpWidget(
      _wrapWithProviders(
        appState: appState,
        child: TrackingScreen(initialOrder: realOrder),
      ),
    );
    await tester.pump();

    expect(find.text('Actualizar estado ahora'), findsOneWidget);
    expect(find.text('Simular avance de motorizado'), findsNothing);
    expect(find.text('Reiniciar contador'), findsNothing);
    expect(find.text('Licoreria Demo Wask'), findsOneWidget);
    expect(find.text('Entrega · Miraflores'), findsOneWidget);
  });

  testWidgets('HomeScreen blocks adding from closed store inside modal',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'wask_access_token': 'demo-jwt',
    });
    final closedClient = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/users/me')) {
        return http.Response(
          jsonEncode(_envelope({
            'id': 'cust-1',
            'firstName': 'Marco',
            'lastName': 'Quispe',
            'email': 'customer@wask.io',
            'role': 'CUSTOMER',
          })),
          200,
        );
      }
      if (path.endsWith('/orders/loyalty')) {
        return http.Response(jsonEncode(_envelope({'deliveredOrders': 0})), 200);
      }
      if (path.endsWith('/business/shops')) {
        return http.Response(
          jsonEncode(_envelope([
            {
              'id': 'biz-closed',
              'companyName': 'Licoreria Nocturna',
              'address': 'Av. Larco 999, Miraflores',
              'operationalStatus': 'PAUSED',
              'isOpenNow': false,
              'openTime': '20:00',
            },
          ])),
          200,
        );
      }
      if (path.endsWith('/products')) {
        return http.Response(
          jsonEncode(_envelope([
            {
              'id': 'prod-c1',
              'name': 'Whisky Black 750ml',
              'category': 'Whisky',
              'price': 140.0,
              'businessId': 'biz-closed',
              'totalStock': 10,
              'business': {'id': 'biz-closed', 'companyName': 'Licoreria Nocturna'},
            },
          ])),
          200,
        );
      }
      return http.Response(jsonEncode(_envelope({})), 200);
    });

    final appState = await AppStateProvider.create(httpClient: closedClient);
    final cart = CartProvider();

    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrapWithProviders(
        appState: appState,
        cartProvider: cart,
        child: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Licoreria Nocturna').first);
    await tester.pumpAndSettle();

    expect(find.text('Cerrado'), findsOneWidget);
    await tester.tap(find.text('Cerrado'));
    await tester.pump();
    expect(cart.totalItems, 0);
  });
}
