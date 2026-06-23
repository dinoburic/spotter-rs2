import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/navigator_key.dart';
import '../../features/auth/login_screen.dart';

class BaseProvider {
  final Dio _dio;
  bool _isRefreshing = false;
  bool _isRedirecting = false;

  BaseProvider() : _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final opts = error.requestOptions;
              final prefs = await SharedPreferences.getInstance();
              final newToken = prefs.getString('accessToken');
              opts.headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
            await _clearSessionAndRedirect();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    _isRefreshing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken') ?? '';
      if (refreshToken.isEmpty) return false;

      final response = await Dio().post(
        '${ApiConstants.baseUrl}${ApiConstants.refresh}',
        data: jsonEncode({'refreshToken': refreshToken}),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;
        await prefs.setString('accessToken', newToken);
        await prefs.setString('refreshToken', newRefreshToken);
        return true;
      }
    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
    return false;
  }

  Future<void> _clearSessionAndRedirect() async {
    if (_isRedirecting) return;
    _isRedirecting = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );

    _isRedirecting = false;
  }

  Future<T> get<T>(
    String endpoint, {
    String? token,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: _createOptions(token),
      );
      return fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(
    String endpoint, {
    String? token,
    dynamic data,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: _createOptions(token),
      );
      return fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> put<T>(
    String endpoint, {
    String? token,
    dynamic data,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: _createOptions(token),
      );
      return fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> delete(
    String endpoint, {
    String? token,
  }) async {
    try {
      await _dio.delete(
        endpoint,
        options: _createOptions(token),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> postAction(
    String endpoint, {
    String? token,
    dynamic data,
  }) async {
    try {
      await _dio.post(
        endpoint,
        data: data,
        options: _createOptions(token),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> uploadFile<T>(
    String endpoint,
    String filePath,
    String fieldName, {
    String? token,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      return fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Options _createOptions(String? token) {
    return Options(
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  Exception _handleError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          return Exception(data['error']);
        }
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors is Map<String, dynamic>) {
            final messages = errors.entries
                .map((entry) {
                  final value = entry.value;
                  if (value is List) {
                    return value.join(', ');
                  }
                  return value.toString();
                })
                .join('; ');
            return Exception(messages);
          }
        }
        if (data.containsKey('message')) {
          return Exception(data['message']);
        }
        if (data.containsKey('title')) {
          return Exception(data['title']);
        }
      }
      if (data is String && data.isNotEmpty) {
        return Exception(data);
      }
    }
    if (e.response?.statusCode == 401) {
      return Exception('Session expired. Please log in again.');
    }
    if (e.response?.statusCode == 403) {
      return Exception('Access denied - You do not have permission for this action');
    }
    if (e.response?.statusCode == 404) {
      return Exception('Resource not found');
    }
    return Exception(e.message ?? 'Request failed (${e.response?.statusCode ?? "unknown"})');
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
