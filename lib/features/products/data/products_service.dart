import '../../../core/network/api_client.dart';
import '../../shared/models/app_models.dart';

class ProductsService {
  ProductsService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Product>> getProducts({
    String? q,
    String? category,
    String? supplierId,
  }) async {
    final query = <String, String>{};
    if (q != null && q.isNotEmpty) {
      query['q'] = q;
    }
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    if (supplierId != null && supplierId.isNotEmpty) {
      query['supplierId'] = supplierId;
    }

    return _apiClient.get<List<Product>>(
      '/products',
      query: query.isEmpty ? null : query,
      parser: (data) => _parseList(data, Product.fromJson),
    );
  }

  Future<Product> createProduct({
    required String name,
    required double price,
    required String category,
    String? supplierId,
    String? brand,
    String? description,
  }) {
    return _apiClient.post<Product>(
      '/products',
      body: {
        'name': name,
        'price': price,
        'category': category,
        if (supplierId != null) 'supplierId': supplierId,
        if (brand != null) 'brand': brand,
        if (description != null) 'description': description,
      },
      parser: (data) => Product.fromJson(_asMap(data)),
    );
  }

  Future<Product> updateProduct({
    required String id,
    String? name,
    double? price,
    String? category,
    String? supplierId,
    String? brand,
    String? description,
  }) {
    return _apiClient.patch<Product>(
      '/products/$id',
      body: {
        if (name != null) 'name': name,
        if (price != null) 'price': price,
        if (category != null) 'category': category,
        if (supplierId != null) 'supplierId': supplierId,
        if (brand != null) 'brand': brand,
        if (description != null) 'description': description,
      },
      parser: (data) => Product.fromJson(_asMap(data)),
    );
  }

  List<Product> _parseList(
    dynamic data,
    Product Function(Map<String, dynamic>) mapper,
  ) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(mapper).toList();
    }
    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().map(mapper).toList();
      }
    }
    return <Product>[];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }
}
