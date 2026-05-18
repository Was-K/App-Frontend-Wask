import '../../../core/network/api_client.dart';
import '../../shared/models/app_models.dart';

class SuppliersService {
  SuppliersService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Supplier>> getSuppliers() {
    return _apiClient.get<List<Supplier>>(
      '/suppliers',
      parser: (data) => _parseList(data, Supplier.fromJson),
    );
  }

  Future<Supplier> createSupplier({
    required String name,
    String? email,
    String? phone,
  }) {
    return _apiClient.post<Supplier>(
      '/suppliers',
      body: {
        'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      },
      parser: (data) => Supplier.fromJson(_asMap(data)),
    );
  }

  Future<Supplier> updateSupplier({
    required String id,
    String? name,
    String? status,
  }) {
    return _apiClient.patch<Supplier>(
      '/suppliers/$id',
      body: {
        if (name != null) 'name': name,
        if (status != null) 'status': status,
      },
      parser: (data) => Supplier.fromJson(_asMap(data)),
    );
  }

  Future<Supplier> verifySupplier(String id) {
    return _apiClient.post<Supplier>(
      '/suppliers/$id/verify',
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
