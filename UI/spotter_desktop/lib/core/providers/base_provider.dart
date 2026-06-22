import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/navigator_key.dart';
import '../../features/auth/login_screen.dart';

class BaseProvider {
  final Dio _dio;

  BaseProvider() : _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('accessToken');
            if (token != null) {
              await prefs.clear();
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          }
          handler.next(error);
        },
      ),
    );
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
      return Exception('Unauthorized - Please login again');
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
