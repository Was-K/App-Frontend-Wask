import '../../../core/network/api_client.dart';
import '../../shared/models/app_models.dart';

/// Servicio de productos para la app del cliente (solo lectura).
///
/// El cliente consume `GET /products` (el backend solo devuelve productos
/// APPROVED + ACTIVE para el rol CUSTOMER) y `GET /products/:id`.
/// La creación/edición de productos es exclusiva del portal web del proveedor
/// (rol BUSINESS_OWNER), por eso aquí no existen.
class ProductsService {
  ProductsService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Product>> getProducts({
    String? q,
    String? category,
    String? businessId,
  }) async {
    final query = <String, String>{};
    if (q != null && q.isNotEmpty) {
      query['q'] = q;
    }
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    if (businessId != null && businessId.isNotEmpty) {
      query['businessId'] = businessId;
    }

    return _apiClient.get<List<Product>>(
      '/products',
      query: query.isEmpty ? null : query,
      parser: (data) => _parseList(data, Product.fromJson),
    );
  }

  Future<Product> getProduct(String id) {
    return _apiClient.get<Product>(
      '/products/$id',
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
