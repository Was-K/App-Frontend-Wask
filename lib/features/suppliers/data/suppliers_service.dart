import '../../../core/network/api_client.dart';
import '../../shared/models/app_models.dart';

/// Servicio de tiendas para la app del cliente.
///
/// En el backend NO existe un modelo `Supplier`: las tiendas son `Business`.
/// El cliente consume los endpoints públicos `GET /business/shops` y
/// `GET /business/shops/:id`, que devuelven solo negocios VERIFIED + ACTIVE.
class SuppliersService {
  SuppliersService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Lista las tiendas disponibles para el cliente. [q] filtra por nombre.
  Future<List<Supplier>> getSuppliers({String? q}) {
    final query = <String, String>{};
    if (q != null && q.trim().isNotEmpty) {
      query['q'] = q.trim();
    }
    return _apiClient.get<List<Supplier>>(
      '/business/shops',
      query: query.isEmpty ? null : query,
      parser: (data) => _parseList(data, Supplier.fromJson),
    );
  }

  /// Detalle de una tienda por id.
  Future<Supplier> getSupplier(String id) {
    return _apiClient.get<Supplier>(
      '/business/shops/$id',
      parser: (data) => Supplier.fromJson(_asMap(data)),
    );
  }

  List<Supplier> _parseList(
    dynamic data,
    Supplier Function(Map<String, dynamic>) mapper,
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
    return <Supplier>[];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }
}
