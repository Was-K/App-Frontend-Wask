import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/wask_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/wask_theme.dart';
import '../../products/data/products_service.dart';
import '../../shared/models/app_models.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_availability_pill.dart';
import '../../shared/widgets/wask_bottom_nav.dart';
import '../../shared/widgets/wask_floating_cart_bar.dart';
import '../../shared/widgets/wask_loyalty_card.dart';
import '../../shared/widgets/wask_product_image.dart';
import '../../shared/widgets/wask_store_availability_pill.dart';
import '../../shop/providers/cart_provider.dart';
import '../../shop/utils/cart_add_helper.dart';
import '../../suppliers/data/suppliers_service.dart';
import '../data/mock_marketplace_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _categories = <String>[
    'Todo',
    'Cerveza',
    'Pisco',
    'Whisky',
    'Vino',
    'Ron',
    'Hielo',
  ];

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'Todo';
  List<Product> _products = <Product>[];
  List<Supplier> _suppliers = <Supplier>[];

  late ProductsService _productsService;
  late SuppliersService _suppliersService;

  bool get _useMocks => AppConfig.enableMocks;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateProvider>();
    final apiClient = appState.apiClient;
    _productsService = ProductsService(apiClient: apiClient);
    _suppliersService = SuppliersService(apiClient: apiClient);
    if (!_useMocks) {
      _loadData();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppStateProvider>().loadLoyaltyStatus();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _productsService.getProducts(),
        _suppliersService.getSuppliers(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _products = results[0] as List<Product>;
        _suppliers = results[1] as List<Supplier>;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Product> get _effectiveProducts {
    if (_useMocks) {
      return marketplaceProducts
          .map(
            (product) => Product(
              id: product.id,
              name: product.name,
              price: product.price,
              category: product.category,
              supplierId: product.supplierId,
              brand: product.brand,
              availableStock: product.availableStock,
              volumeMl: product.volumeMl,
              storeName: product.storeName,
            ),
          )
          .toList();
    }
    return _products;
  }

  List<Supplier> get _effectiveSuppliers {
    if (_useMocks) {
      return marketplaceStores
          .map(
            (store) => Supplier(
              id: store.id,
              name: store.name,
              status: 'ACTIVE',
              isVerified: true,
              address: store.address,
              latitude: store.id == 'mock-0' ? -12.1211 : -12.0910,
              longitude: store.id == 'mock-0' ? -77.0293 : -77.0226,
            ),
          )
          .toList();
    }
    return _suppliers;
  }

  List<Supplier> _sortedSuppliersByDistance(AppStateProvider appState) {
    final list = List<Supplier>.from(_effectiveSuppliers);
    list.sort((a, b) {
      final da = appState.distanceToSupplierKm(a) ?? double.infinity;
      final db = appState.distanceToSupplierKm(b) ?? double.infinity;
      return da.compareTo(db);
    });
    return list;
  }

  String _proximityLabel(double? distKm) {
    if (distKm == null) {
      return 'Disponible cerca de ti · 20-35 min';
    }
    final formatted = distKm.toStringAsFixed(1);
    if (distKm <= 2.5) {
      return 'Cerca de ti · a $formatted km · 20-30 min';
    }
    return 'A $formatted km · 25-35 min';
  }

  List<Product> get _filteredProducts {
    final all = _effectiveProducts;
    if (_selectedCategory == 'Todo') {
      return all;
    }
    final target = _normalizeText(_selectedCategory);
    return all.where((product) {
      final category = _normalizeText(product.category ?? '');
      final name = _normalizeText(product.name);
      final brand = _normalizeText(product.brand ?? '');
      return category.contains(target) ||
          name.contains(target) ||
          brand.contains(target);
    }).toList();
  }

  String _normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  Supplier? _findSupplierById(String? supplierId) {
    if (supplierId == null || supplierId.isEmpty) return null;
    for (final s in _effectiveSuppliers) {
      if (s.id == supplierId) return s;
    }
    return null;
  }

  Future<void> _addOneToCart(
    Product product, {
    String? resolvedStoreName,
    BuildContext? actionContext,
    VoidCallback? onViewCart,
  }) async {
    final supplier = _findSupplierById(product.supplierId);
    await addProductWithStoreGuard(
      actionContext ?? context,
      productId: product.id,
      name: product.name,
      price: product.price,
      quantity: 1,
      supplierId: product.supplierId,
      imageUrl: product.imageUrl,
      storeName: resolvedStoreName ?? product.storeName ?? supplier?.name,
      supplier: supplier,
      onViewCart: onViewCart,
    );
  }

  void _openProductDetail(
    Product product, {
    String? resolvedStoreName,
    double? distanceKm,
  }) {
    final supplier = _findSupplierById(product.supplierId);
    final unavailableReason = getStoreUnavailableReason(context, supplier);
    Navigator.pushNamed(
      context,
      WaskRoutes.productDetail,
      arguments: {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'supplierId': product.supplierId,
        'imageUrl': product.imageUrl,
        'brand': product.brand,
        'description': product.description,
        'availableStock': product.availableStock,
        'storeName': resolvedStoreName ?? product.storeName,
        'distanceKm': distanceKm,
        'isStoreOpen': supplier?.isOpenNow ?? true,
        'inCoverage': supplier?.canDeliverDistance(distanceKm) ?? true,
        'unavailableReason': unavailableReason,
      },
    );
  }

  void _showStoreCatalogModal(Supplier supplier, double? distKm) {
    final storeProducts = _effectiveProducts
        .where((product) => product.supplierId == supplier.id)
        .toList();
    final canDeliver = supplier.canDeliverDistance(distKm);
    final storeAcceptsOrders = supplier.isOpenNow && canDeliver;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: WaskColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (_, scrollController) {
            return ScaffoldMessenger(
              child: Builder(
                builder: (modalMsgCtx) {
                  final modalCart = modalMsgCtx.watch<CartProvider>();
                  return Scaffold(
                    backgroundColor: Colors.transparent,
                    body: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: supplier.logo != null
                                        ? WaskProductImage(
                                            imageUrl: supplier.logo,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/logo.jpg',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              color: WaskColors.surfaceElevated,
                                              child: const Icon(
                                                Icons.storefront_rounded,
                                                color: WaskColors.electricBlue,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              supplier.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (supplier.isVerified == true)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                              decoration: BoxDecoration(
                                                color: WaskColors.emerald
                                                    .withOpacity(0.16),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.verified_rounded,
                                                    size: 13,
                                                    color: WaskColors.emerald,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Verificada',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: WaskColors.emerald,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      if ((supplier.address ?? '')
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          supplier.address!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: WaskColors.secondaryText,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          WaskStoreAvailabilityPill(
                                            isOpenNow: supplier.isOpenNow,
                                            inCoverage: canDeliver,
                                            openTime: supplier.openTime,
                                            maxRadiusKm:
                                                supplier.deliveryRadiusKm,
                                          ),
                                          Text(
                                            _proximityLabel(distKm),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: WaskColors.iceBlue,
                                              fontWeight: FontWeight.w600,
                                              fontFeatures: <FontFeature>[
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Cerrar catalogo',
                                  onPressed: () => Navigator.pop(sheetContext),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                          if (!storeAcceptsOrders)
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    WaskColors.energyOrange.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: WaskColors.energyOrange
                                      .withOpacity(0.45),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: WaskColors.energyOrange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      !supplier.isOpenNow
                                          ? 'Esta tienda está cerrada por ahora${supplier.openTime != null && supplier.openTime != '00:00' ? ' (abre ${supplier.openTime})' : ''}.'
                                          : 'Tu ubicación está fuera del radio de reparto (${supplier.deliveryRadiusKm?.toStringAsFixed(0) ?? '8'} km máx.).',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: WaskColors.primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Divider(height: 1),
                          Expanded(
                            child: storeProducts.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text(
                                        'Esta tienda aun no tiene productos activos en catalogo.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: WaskColors.secondaryText),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: storeProducts.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, index) {
                                      final product = storeProducts[index];
                                      final inCartQty = modalCart
                                              .items[product.id]?.quantity ??
                                          0;
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: WaskColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                              color: WaskColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            WaskProductImage(
                                              imageUrl: product.imageUrl,
                                              width: 64,
                                              height: 64,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    children: [
                                                      WaskAvailabilityPill(
                                                        availableStock: product
                                                            .availableStock,
                                                      ),
                                                      const _ChilledPill(),
                                                      if (inCartQty > 0)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: WaskColors
                                                                .electricBlue
                                                                .withOpacity(
                                                                    0.2),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                          child: Text(
                                                            'En carrito: $inCartQty',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: WaskColors
                                                                  .iceBlue,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'S/ ${product.price.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: WaskColors
                                                          .energyOrange,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 15,
                                                      fontFeatures: <FontFeature>[
                                                        FontFeature
                                                            .tabularFigures(),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: product
                                                              .availableStock <=
                                                          0 ||
                                                      !storeAcceptsOrders
                                                  ? null
                                                  : () => _addOneToCart(
                                                        product,
                                                        resolvedStoreName:
                                                            supplier.name,
                                                        actionContext:
                                                            modalMsgCtx,
                                                        onViewCart: () {
                                                          Navigator.pop(
                                                              sheetContext);
                                                          Navigator.pushNamed(
                                                            context,
                                                            WaskRoutes.cart,
                                                          );
                                                        },
                                                      ),
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10),
                                              ),
                                              child: Text(
                                                !supplier.isOpenNow
                                                    ? 'Cerrado'
                                                    : !canDeliver
                                                        ? 'Fuera de zona'
                                                        : '+ Agregar',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          if (modalCart.totalItems > 0)
                            Container(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 10, 16, 14),
                              decoration: const BoxDecoration(
                                color: WaskColors.surface,
                                border: Border(
                                    top: BorderSide(color: WaskColors.border)),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(sheetContext);
                                    Navigator.pushNamed(
                                        context, WaskRoutes.cart);
                                  },
                                  icon: const Icon(Icons.shopping_cart_rounded),
                                  label: Text(
                                    'Ir al carrito (${modalCart.totalItems}) · S/ ${modalCart.subtotal.toStringAsFixed(2)}',
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().totalItems;
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      bottomNavigationBar: const WaskBottomNav(currentRoute: WaskRoutes.home),
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.pushNamed(context, WaskRoutes.account),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle_outlined,
                    size: 22, color: WaskColors.iceBlue),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Hola, ${appState.displayName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Seguimiento en mapa',
            onPressed: () => Navigator.pushNamed(context, WaskRoutes.tracking),
            icon: const Icon(Icons.delivery_dining_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Carrito',
                  onPressed: () =>
                      Navigator.pushNamed(context, WaskRoutes.cart),
                  icon: const Icon(Icons.shopping_cart_outlined),
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(
                        color: WaskColors.energyOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(context, appState, cartCount),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: const WaskFloatingCartBar(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppStateProvider appState,
    int cartCount,
  ) {
    if (!_useMocks && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_useMocks && _errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredProducts = _filteredProducts;
    final suppliers = _sortedSuppliersByDistance(appState);
    final supplierById = <String, Supplier>{
      for (final s in suppliers) s.id: s,
    };

    return RefreshIndicator(
      onRefresh: _useMocks
          ? () async {}
          : () async {
              await Future.wait([
                _loadData(),
                appState.loadLoyaltyStatus(),
              ]);
            },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              cartCount > 0 ? 92 : 24,
            ),
            children: [
              if (appState.loyaltyBannerMessage != null) ...[
                _TopPushBanner(
                  message: appState.loyaltyBannerMessage!,
                  onDismiss: appState.clearLoyaltyBanner,
                ),
                const SizedBox(height: 12),
              ],
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    Navigator.pushNamed(context, WaskRoutes.addressSelect),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: WaskColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: WaskColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: WaskColors.electricBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appState.selectedAddress?.formattedFullAddress ??
                              appState.selectedAddress?.formatted ??
                              'Selecciona una direccion de entrega en Lima',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.expand_more_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                onTap: () => Navigator.pushNamed(context, WaskRoutes.search),
                decoration: const InputDecoration(
                  hintText: 'Buscar cervezas, pisco, whisky o hielo...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A2647), Color(0xFF0056B3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: WaskColors.electricBlue.withOpacity(0.45)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery en menos de 30 min o es gratis.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Bebidas heladas en Lima · Envio gratis desde S/ 80 o con tu tarjeta de 10 pedidos.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WaskLoyaltyCard(
                onSimulated: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        backgroundColor: WaskColors.emerald,
                        content: Text(
                          '¡Felicidades! 10 pedidos entregados = 1 Delivery Gratis desbloqueado',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Categorias',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    final selected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        selectedColor: WaskColors.electricBlue,
                        backgroundColor: WaskColors.surface,
                        side: BorderSide(
                          color: selected
                              ? WaskColors.electricBlue
                              : WaskColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : WaskColors.secondaryText,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Licorerias Aliadas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (suppliers.isEmpty)
                const Text(
                  'No hay tiendas disponibles por ahora.',
                  style: TextStyle(color: WaskColors.secondaryText),
                )
              else
                ...suppliers.map((supplier) {
                  final storeProductCount = _effectiveProducts
                      .where((p) => p.supplierId == supplier.id)
                      .length;
                  final distKm = appState.distanceToSupplierKm(supplier);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: WaskColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: WaskColors.border),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showStoreCatalogModal(supplier, distKm),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: supplier.logo != null
                                    ? WaskProductImage(
                                        imageUrl: supplier.logo,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/images/logo.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: WaskColors.surfaceElevated,
                                          child: const Icon(
                                            Icons.storefront_rounded,
                                            color: WaskColors.electricBlue,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          supplier.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (supplier.isVerified == true)
                                        const Icon(
                                          Icons.verified_rounded,
                                          size: 16,
                                          color: WaskColors.emerald,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if ((supplier.address ?? '').isNotEmpty)
                                    Text(
                                      supplier.address!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: WaskColors.secondaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      WaskStoreAvailabilityPill(
                                        isOpenNow: supplier.isOpenNow,
                                        inCoverage:
                                            supplier.canDeliverDistance(distKm),
                                        openTime: supplier.openTime,
                                        maxRadiusKm: supplier.deliveryRadiusKm,
                                      ),
                                      Text(
                                        _proximityLabel(distKm),
                                        style: const TextStyle(
                                          color: WaskColors.iceBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          fontFeatures: <FontFeature>[
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                      const Text(
                                        '·',
                                        style: TextStyle(
                                            color: WaskColors.secondaryText),
                                      ),
                                      Text(
                                        '$storeProductCount productos',
                                        style: const TextStyle(
                                          color: WaskColors.secondaryText,
                                          fontSize: 12,
                                          fontFeatures: <FontFeature>[
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: WaskColors.secondaryText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCategory == 'Todo'
                          ? 'Catalogo helado'
                          : 'Catalogo · $_selectedCategory',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${filteredProducts.length} items',
                    style: const TextStyle(
                      color: WaskColors.secondaryText,
                      fontSize: 12,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filteredProducts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: WaskColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: WaskColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'No hay productos disponibles en esta categoria.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: WaskColors.secondaryText),
                      ),
                      if (_selectedCategory != 'Todo') ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'Todo';
                            });
                          },
                          child: const Text('Ver todo el catalogo'),
                        ),
                      ],
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 920
                        ? 4
                        : width >= 600
                            ? 3
                            : 2;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 286,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final supplier = supplierById[product.supplierId ?? ''];
                        final resolvedStoreName =
                            product.storeName ?? supplier?.name;
                        final distKm = supplier == null
                            ? null
                            : appState.distanceToSupplierKm(supplier);
                        return _ProductCatalogCard(
                          product: product,
                          storeName: resolvedStoreName,
                          distanceKm: distKm,
                          storeOpen: supplier?.isOpenNow ?? true,
                          inCoverage:
                              supplier?.canDeliverDistance(distKm) ?? true,
                          onTap: () => _openProductDetail(
                            product,
                            resolvedStoreName: resolvedStoreName,
                            distanceKm: distKm,
                          ),
                          onAdd: () => _addOneToCart(
                            product,
                            resolvedStoreName: resolvedStoreName,
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return 'Tu sesion expiro. Inicia sesion nuevamente.';
      }
      if (error.statusCode == 404) {
        return 'No se encontraron productos.';
      }
      if (error.statusCode != null && error.statusCode! >= 500) {
        return 'El servidor tuvo un problema. Intenta luego.';
      }
      return error.message;
    }
    return 'No se pudo cargar la informacion.';
  }
}

class _TopPushBanner extends StatelessWidget {
  const _TopPushBanner({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WaskColors.emerald.withOpacity(0.18),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WaskColors.emerald.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: WaskColors.emerald,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCatalogCard extends StatelessWidget {
  const _ProductCatalogCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.storeName,
    this.distanceKm,
    this.storeOpen = true,
    this.inCoverage = true,
  });

  final Product product;
  final String? storeName;
  final double? distanceKm;
  final bool storeOpen;
  final bool inCoverage;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final canOrder = product.availableStock > 0 && storeOpen && inCoverage;
    return Container(
      decoration: BoxDecoration(
        color: WaskColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WaskColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  WaskProductImage(
                    imageUrl: product.imageUrl,
                    width: double.infinity,
                    height: 112,
                    borderRadius: BorderRadius.circular(12),
                    fit: BoxFit.contain,
                  ),
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: _ChilledPill(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  WaskAvailabilityPill(availableStock: product.availableStock),
                  if (distanceKm != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: WaskColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'A ${distanceKm!.toStringAsFixed(1)} km',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: WaskColors.iceBlue,
                          fontWeight: FontWeight.w600,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _subtitle(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: WaskColors.secondaryText,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'S/ ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: WaskColors.energyOrange,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        fontFeatures: <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                  Material(
                    color: canOrder
                        ? WaskColors.electricBlue
                        : WaskColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: product.availableStock <= 0 ? null : onAdd,
                      child: SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          canOrder ? Icons.add_rounded : Icons.block_rounded,
                          color: canOrder ? Colors.white : Colors.white38,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[
      if ((product.brand ?? '').isNotEmpty) product.brand!,
      if (product.volumeMl != null) '${product.volumeMl}ml',
      if ((storeName ?? '').isNotEmpty) storeName!,
    ];
    if (parts.isEmpty) {
      return product.category ?? 'Delivery WASK';
    }
    return parts.join(' · ');
  }
}

class _ChilledPill extends StatelessWidget {
  const _ChilledPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: WaskColors.iceBlue.withOpacity(0.55)),
      ),
      child: const Text(
        'Helada ❄️',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: WaskColors.iceBlue,
        ),
      ),
    );
  }
}
