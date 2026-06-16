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
      throw _handleError(e);
    }
  }

  Future<void> _handleUnauthorized(String? requestPath) async {
    if (_isRedirecting) return;
    if (requestPath == ApiConstants.login ||
        requestPath == ApiConstants.register) return;

    _isRedirecting = true;

    await onUnauthorized?.call();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('role');

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );

    _isRedirecting = false;
  }

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 401) {
      _handleUnauthorized(e.requestOptions.path);
      return Exception('Session expired');
    }
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return Exception(data['message']);
      }
      if (data is Map && data.containsKey('title')) {
        return Exception(data['title']);
      }
    }
    return Exception(e.message ?? 'An error occurred');
  }
}
