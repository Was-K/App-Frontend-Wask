import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/token_storage.dart';
import '../../shared/models/app_models.dart';

class AuthService {
  AuthService({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthTokens> login(String email, String password) async {
    final tokens = await _apiClient.post<AuthTokens>(
      '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
      parser: (data) => AuthTokens.fromJson(_asMap(data)),
    );
    await _tokenStorage.saveAccessToken(tokens.accessToken);
    await _tokenStorage.saveRefreshToken(tokens.refreshToken);
    return tokens;
  }

  /// Registro de cliente final. El backend crea un usuario CUSTOMER activo
  /// (endpoint público POST /auth/register-customer). No emite tokens: tras
  /// registrarse el usuario debe iniciar sesión.
  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) {
    return _apiClient.post<AppUser>(
      '/auth/register-customer',
      body: {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
      parser: (data) => AppUser.fromJson(_asMap(data)),
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post<void>(
        '/auth/logout',
        parser: (_) => null,
      );
    } catch (_) {
      // Ignore logout errors to avoid blocking local cleanup.
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  Future<AuthTokens> refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException('No hay refresh token disponible.');
    }

    final tokens = await _apiClient.post<AuthTokens>(
      '/auth/refresh-token',
      body: {'refreshToken': refreshToken},
      parser: (data) => AuthTokens.fromJson(_asMap(data)),
    );

    await _tokenStorage.saveAccessToken(tokens.accessToken);
    await _tokenStorage.saveRefreshToken(tokens.refreshToken);
    return tokens;
  }

  Future<AppUser?> getCurrentUser() async {
    return _apiClient.get<AppUser?>(
      '/users/me',
      parser: (data) {
        if (data == null) {
          return null;
        }
        return AppUser.fromJson(_asMap(data));
      },
    );
  }

  Future<bool> validateSession() async {
    return _apiClient.post<bool>(
      '/auth/validate-session',
      parser: (data) {
        if (data is bool) {
          return data;
        }
        if (data is Map<String, dynamic>) {
          final valid = data['valid'];
          if (valid is bool) {
            return valid;
          }
        }
        return false;
      },
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }
}
