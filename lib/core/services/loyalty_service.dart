import '../../features/shared/models/app_models.dart';
import '../network/api_client.dart';

/// Servicio de fidelizacion WASK (10 pedidos entregados = 1 Delivery Gratis).
class LoyaltyService {
  LoyaltyService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<LoyaltyStatus> getLoyaltyStatus() {
    return _apiClient.get<LoyaltyStatus>(
      '/orders/loyalty',
      parser: (data) => LoyaltyStatus.fromJson(_asMap(data)),
    );
  }

  Future<LoyaltyStatus> simulateTenDeliveredOrders() {
    return _apiClient.post<LoyaltyStatus>(
      '/orders/loyalty/simulate',
      parser: (data) => LoyaltyStatus.fromJson(_asMap(data)),
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }
}
