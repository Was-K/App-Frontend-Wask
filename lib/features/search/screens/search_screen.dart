import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../home/data/mock_marketplace_data.dart';
import '../../products/data/products_service.dart';
import '../../shared/models/app_models.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_availability_pill.dart';
import '../../shared/widgets/wask_bottom_nav.dart';
import '../../shared/widgets/wask_floating_cart_bar.dart';
import '../../shared/widgets/wask_product_image.dart';
import '../../shared/widgets/wask_store_availability_pill.dart';
import '../../shop/providers/cart_provider.dart';
import '../../shop/utils/cart_add_helper.dart';
import '../../suppliers/data/suppliers_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const List<String> _trendingTerms = <String>[
    'Pilsen',
    'Cristal',
    'Cusquena',
    'Pisco',
    'Whisky',
    'Hielo',
  ];

  final _controller = TextEditingController();
  Timer? _debounce;
  int _requestSequence = 0;

  bool _isInitialLoading = false;
  bool _isSearchingRemote = false;
  String? _errorMessage;

  List<Product> _catalog = <Product>[];
  List<Product>? _remoteResults;
  Map<String, String> _storeNames = <String, String>{};
  Map<String, Supplier> _suppliersById = <String, Supplier>{};

  late ProductsService _productsService;
  late SuppliersService _suppliersService;

  bool get _useMocks => AppConfig.enableMocks;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AppStateProvider>().apiClient;
    _productsService = ProductsService(apiClient: apiClient);
    _suppliersService = SuppliersService(apiClient: apiClient);
    if (_useMocks) {
      _loadMockCatalog();
    } else {
      _loadInitialCatalog();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _loadMockCatalog() {
    _suppliersById = <String, Supplier>{
      for (final s in marketplaceStores)
        s.id: Supplier(
          id: s.id,
          name: s.name,
          status: 'ACTIVE',
          isVerified: true,
          address: s.address,
          latitude: s.id == 'mock-0' ? -12.1211 : -12.0910,
          longitude: s.id == 'mock-0' ? -77.0293 : -77.0226,
        ),
    };
    _storeNames = <String, String>{
      for (final s in marketplaceStores) s.id: s.name,
    };
    _catalog = marketplaceProducts
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

  Future<void> _loadInitialCatalog() async {
    setState(() {
      _isInitialLoading = true;
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
      final products = results[0] as List<Product>;
      final suppliers = results[1] as List<Supplier>;
      setState(() {
        _catalog = products;
        _suppliersById = <String, Supplier>{
          for (final s in suppliers) s.id: s,
        };
        _storeNames = <String, String>{
          for (final s in suppliers) s.id: s.name,
        };
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'No se pudo cargar el catalogo de busqueda.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  void _onQueryChanged(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _remoteResults = null;
      }
    });

    if (_useMocks) {
      return;
    }

    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _requestSequence++;
      setState(() {
        _isSearchingRemote = false;
        _remoteResults = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 260), () {
      _fetchRemoteSearch(trimmed);
    });
  }

  Future<void> _fetchRemoteSearch(String query) async {
    final seq = ++_requestSequence;
    setState(() {
      _isSearchingRemote = true;
    });
    try {
      final results = await _productsService.getProducts(q: query);
      if (!mounted || seq != _requestSequence) {
        return;
      }
      setState(() {
        _remoteResults = results;
      });
    } catch (_) {
      // Mantiene filtrado local instantaneo si la consulta remota falla.
    } finally {
      if (mounted && seq == _requestSequence) {
        setState(() {
          _isSearchingRemote = false;
        });
      }
    }
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  List<Product> _visibleProducts() {
    final raw = _controller.text;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return _catalog;
    }

    final term = _normalize(trimmed);
    final localMatches = _catalog.where((product) {
      final storeName =
          product.storeName ?? _storeNames[product.supplierId ?? ''] ?? '';
      final haystack = _normalize(
        '${product.name} ${product.brand ?? ''} ${product.category ?? ''} $storeName ${product.sku ?? ''}',
      );
      return haystack.contains(term);
    }).toList();

    final remote = _remoteResults;
    if (remote == null || remote.isEmpty) {
      return localMatches;
    }

    final merged = <String, Product>{
      for (final p in remote) p.id: p,
      for (final p in localMatches) p.id: p,
    };
    return merged.values.toList();
  }

  void _selectTrending(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    _onQueryChanged(term);
  }

  Future<void> _addToCart(Product product, String storeName) async {
    final supplier = _suppliersById[product.supplierId ?? ''];
    await addProductWithStoreGuard(
      context,
      productId: product.id,
      name: product.name,
      price: product.price,
      quantity: 1,
      supplierId: product.supplierId,
      imageUrl: product.imageUrl,
      storeName: storeName,
      supplier: supplier,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().totalItems;
    final results = _visibleProducts();
    final hasQuery = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar bebidas'),
      ),
      bottomNavigationBar: const WaskBottomNav(currentRoute: WaskRoutes.search),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controller,
                        onChanged: _onQueryChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText:
                              'Busca Pilsen, Cristal, Cusquena, Pisco, Whisky, Hielo...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _controller.text.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Limpiar busqueda',
                                  onPressed: () {
                                    _controller.clear();
                                    _onQueryChanged('');
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tendencias ahora',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: WaskColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _trendingTerms.map((term) {
                            final isSelected =
                                _normalize(_controller.text.trim()) ==
                                    _normalize(term);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                avatar: Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : WaskColors.energyOrange,
                                ),
                                label: Text(term),
                                backgroundColor: isSelected
                                    ? WaskColors.electricBlue
                                    : WaskColors.surface,
                                side: BorderSide(
                                  color: isSelected
                                      ? WaskColors.electricBlue
                                      : WaskColors.border,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : WaskColors.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                                onPressed: () => _selectTrending(term),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isSearchingRemote)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      Expanded(
                        child: _buildResultsBody(
                          results: results,
                          hasQuery: hasQuery,
                          cartCount: cartCount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: const WaskFloatingCartBar(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsBody({
    required List<Product> results,
    required bool hasQuery,
    required int cartCount,
  }) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _catalog.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadInitialCatalog,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            hasQuery
                ? 'No encontramos productos para "${_controller.text.trim()}". Prueba con Pilsen, Cristal, Pisco o Hielo.'
                : 'No hay productos disponibles en el catalogo.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: WaskColors.secondaryText),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: cartCount > 0 ? 88 : 20),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final product = results[index];
        final supplier = _suppliersById[product.supplierId ?? ''];
        final storeName = product.storeName ??
            _storeNames[product.supplierId ?? ''] ??
            'Licoreria Aliada';
        final appState = context.read<AppStateProvider>();
        final distKm =
            supplier == null ? null : appState.distanceToSupplierKm(supplier);
        final isStoreOpen = supplier?.isOpenNow ?? true;
        final inCoverage = supplier?.canDeliverDistance(distKm) ?? true;
        final unavailableReason = getStoreUnavailableReason(context, supplier);
        final brandVolume = <String>[
          if ((product.brand ?? '').isNotEmpty) product.brand!,
          if (product.volumeMl != null) '${product.volumeMl}ml',
        ].join(' · ');

        return Container(
          decoration: BoxDecoration(
            color: WaskColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: WaskColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pushNamed(
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
                'storeName': storeName,
                'distanceKm': distKm,
                'isStoreOpen': isStoreOpen,
                'inCoverage': inCoverage,
                'unavailableReason': unavailableReason,
              },
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  WaskProductImage(
                    imageUrl: product.imageUrl,
                    width: 68,
                    height: 68,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (brandVolume.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            brandVolume,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: WaskColors.iceBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            WaskAvailabilityPill(
                              availableStock: product.availableStock,
                            ),
                            if (!isStoreOpen || !inCoverage)
                              WaskStoreAvailabilityPill(
                                isOpenNow: isStoreOpen,
                                inCoverage: inCoverage,
                                openTime: supplier?.openTime,
                                maxRadiusKm: supplier?.deliveryRadiusKm,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'S/ ${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: WaskColors.energyOrange,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        onPressed: product.availableStock <= 0
                            ? null
                            : () => _addToCart(product, storeName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (!isStoreOpen || !inCoverage)
                              ? WaskColors.surfaceElevated
                              : null,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          minimumSize: const Size(0, 34),
                        ),
                        child: Text(
                          !isStoreOpen
                              ? 'Cerrado'
                              : !inCoverage
                                  ? 'Fuera de zona'
                                  : '+ Agregar',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
