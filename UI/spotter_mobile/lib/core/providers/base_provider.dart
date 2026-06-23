import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../constants/navigator_key.dart';
import '../../features/auth/login_screen.dart';

class BaseProvider {
  late final Dio _dio;
  String? _token;
  Future<void> Function()? onUnauthorized;
  bool _isRedirecting = false;
  bool _isRefreshing = false;

  BaseProvider() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
    ));
  }

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _headers()),
      );
      return fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return await _handleUnauthorizedWithRetry<T>(
          () => get<T>(path, queryParameters: queryParameters, fromJson: fromJson),
          e.requestOptions.path,
        );
      }
      throw _handleError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(headers: _headers()),
      );
      return fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return await _handleUnauthorizedWithRetry<T>(
          () => post<T>(path, data: data, fromJson: fromJson),
          e.requestOptions.path,
        );
      }
      throw _handleError(e);
    }
  }

  Future<void> postAction(
    String path, {
    dynamic data,
  }) async {
    try {
      await _dio.post(
        path,
        data: data,
        options: Options(headers: _headers()),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleUnauthorizedWithRetry<void>(
          () => postAction(path, data: data),
          e.requestOptions.path,
        );
        return;
      }
      throw _handleError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        options: Options(headers: _headers()),
      );
      return fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return await _handleUnauthorizedWithRetry<T>(
          () => put<T>(path, data: data, fromJson: fromJson),
          e.requestOptions.path,
        );
      }
      throw _handleError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(
        path,
        options: Options(headers: _headers()),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _handleUnauthorizedWithRetry<void>(
          () => delete(path),
          e.requestOptions.path,
        );
        return;
      }
      throw _handleError(e);
    }
  }

  Future<T> uploadFile<T>(
    String path,
    String filePath,
    String fieldName, {
    required T Function(dynamic) fromJson,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Authorization': _token != null ? 'Bearer $_token' : null,
          },
          contentType: 'multipart/form-data',
        ),
      );
      return fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return await _handleUnauthorizedWithRetry<T>(
          () => uploadFile<T>(path, filePath, fieldName, fromJson: fromJson),
          e.requestOptions.path,
        );
      }
      throw _handleError(e);
    }
  }

  Future<T> _handleUnauthorizedWithRetry<T>(
    Future<T> Function() retryRequest,
    String? requestPath,
  ) async {
    if (requestPath == ApiConstants.login ||
        requestPath == ApiConstants.register ||
        requestPath == ApiConstants.refresh) {
      _redirectToLogin();
      throw Exception('Session expired. Please log in again.');
    }

    if (_isRefreshing) {
      _redirectToLogin();
      throw Exception('Session expired. Please log in again.');
    }

    _isRefreshing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken') ?? '';

      if (refreshToken.isEmpty) {
        _redirectToLogin();
        throw Exception('Session expired. Please log in again.');
      }

      final response = await _dio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String? ?? '';
        await prefs.setString('accessToken', newToken);
        if (newRefreshToken.isNotEmpty) {
          await prefs.setString('refreshToken', newRefreshToken);
        }
        _token = newToken;
        _isRefreshing = false;
        return await retryRequest();
      } else {
        _redirectToLogin();
        throw Exception('Session expired. Please log in again.');
      }
    } catch (e) {
      _isRefreshing = false;
      _redirectToLogin();
      throw Exception('Session expired. Please log in again.');
    }
  }

  void _redirectToLogin() {
    if (_isRedirecting) return;
    _isRedirecting = true;

    onUnauthorized?.call();

    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('accessToken');
      prefs.remove('refreshToken');
      prefs.remove('userId');
      prefs.remove('username');
      prefs.remove('role');
    });

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _isRedirecting = false;
    });
  }

  Exception _handleError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data.containsKey('error')) {
          return Exception(data['error']);
        }
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors is Map) {
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
    return Exception(e.message ?? 'Request failed (${e.response?.statusCode ?? "unknown"})');
  }
}
