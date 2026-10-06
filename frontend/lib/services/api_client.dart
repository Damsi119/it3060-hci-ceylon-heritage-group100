import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_config.dart';
import 'token_store.dart';

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<dynamic> get(String path, {bool authenticated = true}) {
    return _request('GET', path, authenticated: authenticated);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _request('POST', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _request('PUT', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _request('DELETE', path, body: body, authenticated: authenticated);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool authenticated,
    bool retryAfterRefresh = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final accessToken = await TokenStore.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    final encodedBody = body == null ? null : jsonEncode(body);
    late http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await http.get(_uri(path), headers: headers);
          break;
        case 'POST':
          response = await http.post(
            _uri(path),
            headers: headers,
            body: encodedBody,
          );
          break;
        case 'PUT':
          response = await http.put(
            _uri(path),
            headers: headers,
            body: encodedBody,
          );
          break;
        case 'DELETE':
          response = await http.delete(
            _uri(path),
            headers: headers,
            body: encodedBody,
          );
          break;
        default:
          throw const ApiException('Unsupported request method');
      }
    } on http.ClientException catch (error) {
      throw ApiException(
        'Could not connect to ${ApiConfig.baseUrl}. Check that Spring Boot is running and that this address is reachable. (${error.message})',
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('Request to ${_uri(path)} failed: $error');
    }

    if (response.statusCode == 401 && authenticated && retryAfterRefresh) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        return _request(
          method,
          path,
          body: body,
          authenticated: authenticated,
          retryAfterRefresh: false,
        );
      }
    }

    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    dynamic data;
    if (response.body.trim().isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String message = 'Something went wrong';
    if (data is Map<String, dynamic> && data['message'] is String) {
      message = data['message'] as String;
    } else if (data is String && data.trim().isNotEmpty) {
      message = data;
    }

    throw ApiException(message, response.statusCode);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await TokenStore.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        _uri('/api/auth/refresh'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await TokenStore.clear();
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await TokenStore.saveTokens(
        data['accessToken'] as String? ?? '',
        data['refreshToken'] as String? ?? '',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
