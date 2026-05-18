import '../../../core/network/api_client.dart';
import '../../shared/models/app_models.dart';

class OrdersService {
  OrdersService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<OrderRecord>> getOrders() {
    return _apiClient.get<List<OrderRecord>>(
      '/orders',
      parser: (data) => _parseList(data, OrderRecord.fromJson),
    );
  }

  Future<OrderRecord> createOrder({
    required String businessId,
    required String supplierId,
    required List<OrderLine> items,
    String? notes,
  }) {
    return _apiClient.post<OrderRecord>(
      '/orders',
      body: {
        'businessId': businessId,
        'supplierId': supplierId,
        'items': items
            .map((item) => {
                  'productId': item.productId,
                  'quantity': item.quantity,
                })
            .toList(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      parser: (data) => OrderRecord.fromJson(_asMap(data)),
    );
  }

  Future<OrderRecord> updateOrderStatus({
    required String orderId,
    required String status,
  }) {
    return _apiClient.patch<OrderRecord>(
      '/orders/$orderId/status',
      body: {'status': status},
      parser: (data) => OrderRecord.fromJson(_asMap(data)),
    );
  }

  List<OrderRecord> _parseList(
    dynamic data,
    OrderRecord Function(Map<String, dynamic>) mapper,
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
    return <OrderRecord>[];
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }
}
