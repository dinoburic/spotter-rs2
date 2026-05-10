import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class BaseProvider {
  late final Dio _dio;
  String? _token;

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

  Exception _handleError(DioException e) {
    if (e.response?.statusCode == 401) {
      return Exception('Unauthorized');
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
