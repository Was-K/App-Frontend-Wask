import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    http.Client? httpClient,
  })  : _tokenStorage = tokenStorage,
        _httpClient = httpClient ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _httpClient;

  static const Duration _timeout = Duration(seconds: 20);

  Future<T> get<T>(
    String path, {
    Map<String, String>? query,
    required T Function(dynamic data) parser,
  }) {
    return _send(
      'GET',
      path,
      query: query,
      parser: parser,
    );
  }

  Future<T> post<T>(
    String path, {
    Map<String, String>? query,
    Object? body,
    required T Function(dynamic data) parser,
  }) {
    return _send(
      'POST',
      path,
      query: query,
      body: body,
      parser: parser,
    );
  }

  Future<T> patch<T>(
    String path, {
    Map<String, String>? query,
    Object? body,
    required T Function(dynamic data) parser,
  }) {
    return _send(
      'PATCH',
      path,
      query: query,
      body: body,
      parser: parser,
    );
  }

  Future<T> delete<T>(
    String path, {
    Map<String, String>? query,
    Object? body,
    required T Function(dynamic data) parser,
  }) {
    return _send(
      'DELETE',
      path,
      query: query,
      body: body,
      parser: parser,
    );
  }

  Future<T> _send<T>(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required T Function(dynamic data) parser,
    bool retryOnUnauthorized = true,
  }) async {
    final uri = _buildUri(path, query);
    final headers = await _buildHeaders();

    try {
      final response = await _dispatch(
        method,
        uri,
        headers: headers,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 401 && retryOnUnauthorized) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return _send(
            method,
            path,
            query: query,
            body: body,
            parser: parser,
            retryOnUnauthorized: false,
          );
        }
        await _tokenStorage.clearTokens();
        throw ApiException(
          'Tu sesion expiro. Inicia sesion nuevamente.',
          statusCode: 401,
        );
      }

      final decoded = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _extractMessage(
          decoded,
          fallback: 'Error inesperado del servidor.',
        );
        throw ApiException(
          message,
          statusCode: response.statusCode,
          details: decoded,
        );
      }

      if (decoded is Map<String, dynamic>) {
        final success = decoded['success'];
        if (success == false) {
          final message = _extractMessage(
            decoded,
            fallback: 'La operacion no fue exitosa.',
          );
          throw ApiException(
            message,
            statusCode: response.statusCode,
            details: decoded,
          );
        }
        return parser(decoded['data']);
      }

      return parser(decoded);
    } on TimeoutException catch (_) {
      throw ApiException('Tiempo de espera agotado.');
    } on ApiException {
      rethrow;
    } catch (error) {
      debugPrint('ApiClient error: $error');
      throw ApiException(
        'No se pudo conectar con el servidor.',
        details: error,
      );
    }
  }

  Future<http.Response> _dispatch(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    switch (method) {
      case 'GET':
        return _httpClient.get(uri, headers: headers);
      case 'POST':
        return _httpClient.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'PATCH':
        return _httpClient.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'DELETE':
        return _httpClient.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      default:
        throw ApiException('Metodo HTTP no soportado: $method');
    }
  }

  Uri _buildUri(String path, Map<String, String>? query) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    final uri = Uri.parse('$base$normalizedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: query);
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = _baseHeaders();
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, String> _baseHeaders() {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  dynamic _decodeBody(String body) {
    if (body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _extractMessage(dynamic decoded, {required String fallback}) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'] ??
          decoded['error'] ??
          (decoded['data'] is Map<String, dynamic>
              ? (decoded['data'] as Map<String, dynamic>)['message']
              : null);
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final uri = _buildUri('/auth/refresh-token', null);
      final response = await _httpClient
          .post(
            uri,
            headers: _baseHeaders(),
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final decoded = _decodeBody(response.body);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        return false;
      }

      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) {
        return false;
      }

      await _tokenStorage.saveAccessToken(newAccess);
      await _tokenStorage.saveRefreshToken(newRefresh);
      return true;
    } catch (error) {
      debugPrint('Refresh token failed: $error');
      return false;
    }
  }
}
