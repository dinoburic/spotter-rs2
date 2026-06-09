import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/category_response.dart';
import '../models/category_request.dart';
import '../models/page_result.dart';

class CategoryProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<CategoryResponse> items = [];
  int currentPage = 1;
  int pageSize = 10;
  int? totalCount;
  bool isLoading = false;
  String? error;

  CategoryProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  Future<void> loadAll({String? name}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': currentPage,
        'pageSize': pageSize,
      };
      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      final result = await _baseProvider.get<PageResult<CategoryResponse>>(
        ApiConstants.categories,
        token: _token,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => CategoryResponse.fromJson(item),
        ),
      );

      items = result.items;
      totalCount = result.totalCount;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<CategoryResponse>> loadForDropdown() async {
    final result = await _baseProvider.get<PageResult<CategoryResponse>>(
      ApiConstants.categories,
      token: _token,
      queryParameters: {'pageSize': 100},
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => CategoryResponse.fromJson(item),
      ),
    );
    return result.items;
  }

  Future<CategoryResponse> getById(int id) async {
    return await _baseProvider.get<CategoryResponse>(
      '${ApiConstants.categories}/$id',
      token: _token,
      fromJson: (json) => CategoryResponse.fromJson(json),
    );
  }

  Future<void> insert(CategoryRequest request) async {
    await _baseProvider.post<CategoryResponse>(
      ApiConstants.categories,
      token: _token,
      data: request.toJson(),
      fromJson: (json) => CategoryResponse.fromJson(json),
    );
  }

  Future<void> update(int id, CategoryRequest request) async {
    await _baseProvider.put<CategoryResponse>(
      '${ApiConstants.categories}/$id',
      token: _token,
      data: request.toJson(),
      fromJson: (json) => CategoryResponse.fromJson(json),
    );
  }

  Future<void> delete(int id) async {
    await _baseProvider.delete(
      '${ApiConstants.categories}/$id',
      token: _token,
    );
  }

  void setPage(int page) {
    currentPage = page;
  }
}
