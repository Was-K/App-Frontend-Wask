import '../../../core/network/api_client.dart';

class LogisticsService {
  LogisticsService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getShipments() {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/logistics/shipments',
      parser: (data) {
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
        return <Map<String, dynamic>>[];
      },
    );
  }

  Future<Map<String, dynamic>> createShipment({
    required String orderId,
    required String courierId,
  }) {
    return _apiClient.post<Map<String, dynamic>>(
      '/logistics/shipments',
      body: {
        'orderId': orderId,
        'courierId': courierId,
      },
      parser: (data) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        return <String, dynamic>{};
      },
    );
  }

  Future<Map<String, dynamic>> updateShipmentStatus({
    required String shipmentId,
    required String status,
  }) {
    return _apiClient.patch<Map<String, dynamic>>(
      '/logistics/shipments/$shipmentId/status',
      body: {'status': status},
      parser: (data) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        return <String, dynamic>{};
      },
    );
  }
}
