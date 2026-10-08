import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/constants/api_config.dart';
import '../models/user_profile.dart';
import 'api_client.dart';
import 'token_store.dart';

class UserService {
  UserService._();

  static final UserService instance = UserService._();
  final ApiClient _api = ApiClient.instance;

  Future<UserProfile> getProfile() async {
    final data = await _api.get('/api/users/me') as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
  }) async {
    final data =
        await _api.put(
              '/api/users/me',
              body: {
                'firstName': firstName,
                'lastName': lastName,
                'phone': phone,
                'address': address,
              },
            )
            as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfilePhoto({
    required Uint8List bytes,
    required String filename,
    required String subtype,
  }) {
    return _uploadProfileImage(
      '/api/users/me/profile-photo',
      bytes: bytes,
      filename: filename,
      subtype: subtype,
    );
  }

  Future<UserProfile> updateCoverPhoto({
    required Uint8List bytes,
    required String filename,
    required String subtype,
  }) {
    return _uploadProfileImage(
      '/api/users/me/cover-photo',
      bytes: bytes,
      filename: filename,
      subtype: subtype,
    );
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final data =
        await _api.put(
              '/api/users/me/password',
              body: {
                'currentPassword': currentPassword,
                'newPassword': newPassword,
                'confirmPassword': confirmPassword,
              },
            )
            as Map<String, dynamic>;
    return data['message'] as String? ?? 'Password changed';
  }

  Future<UserProfile> _uploadProfileImage(
    String path, {
    required Uint8List bytes,
    required String filename,
    required String subtype,
    bool retryAfterRefresh = true,
  }) async {
    final token = await TokenStore.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please log in to upload a photo.', 403);
    }

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${_baseUrl()}$path'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: filename,
        contentType: MediaType('image', subtype),
      ),
    );

    late http.Response response;
    try {
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      response = await http.Response.fromStream(streamed);
    } catch (error) {
      throw ApiException('Photo upload failed: $error');
    }

    if (response.statusCode == 401 && retryAfterRefresh) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _uploadProfileImage(
          path,
          bytes: bytes,
          filename: filename,
          subtype: subtype,
          retryAfterRefresh: false,
        );
      }
    }

    final decoded = _decodeMultipartResponse(response);
    if (decoded is Map<String, dynamic>) {
      return UserProfile.fromJson(decoded);
    }

    throw const ApiException('Invalid profile response.');
  }

  dynamic _decodeMultipartResponse(http.Response response) {
    dynamic data;
    final body = utf8.decode(response.bodyBytes).trim();
    if (body.isNotEmpty) {
      try {
        data = jsonDecode(body);
      } catch (_) {
        data = body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (response.statusCode == 401) {
      throw const ApiException(
        'Your session expired. Please log in again.',
        401,
      );
    }

    if (response.statusCode == 403) {
      throw const ApiException('Please log in to perform this action.', 403);
    }

    var message = 'Photo upload failed.';
    if (data is Map<String, dynamic> && data['message'] is String) {
      message = data['message'] as String;
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    throw ApiException(message, response.statusCode);
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await TokenStore.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http
          .post(
            Uri.parse('${_baseUrl()}/api/auth/refresh'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await TokenStore.clear();
        return false;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) return false;

      await TokenStore.saveTokens(
        data['accessToken'] as String? ?? '',
        data['refreshToken'] as String? ?? '',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String _baseUrl() => ApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '');

  Future<void> logout() async {
    try {
      await _api.post('/api/users/logout');
    } finally {
      await TokenStore.clear();
    }
  }

  Future<String> deleteAccount(String currentPassword) async {
    final data =
        await _api.delete(
              '/api/users/me',
              body: {'currentPassword': currentPassword},
            )
            as Map<String, dynamic>;
    await TokenStore.clear();
    return data['message'] as String? ?? 'Account deleted';
  }
}
