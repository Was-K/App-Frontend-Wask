import '../../../core/network/api_client.dart';

class DashboardService {
  DashboardService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> getDashboardSummary() {
    return _apiClient.get<Map<String, dynamic>>(
      '/dashboard/summary',
      parser: (data) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        return <String, dynamic>{};
      },
    );
  }
}
