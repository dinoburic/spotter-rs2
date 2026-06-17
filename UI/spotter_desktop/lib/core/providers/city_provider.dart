import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/city_response.dart';
import '../models/city_request.dart';
import '../models/page_result.dart';

class CityProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<CityResponse> items = [];
  int currentPage = 1;
  int pageSize = 10;
  int? totalCount;
  bool isLoading = false;
  String? error;

  CityProvider(this._baseProvider, this._authProvider);

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
        'includeTotalCount': true,
      };
      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      final result = await _baseProvider.get<PageResult<CityResponse>>(
        ApiConstants.cities,
        token: _token,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => CityResponse.fromJson(item),
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

  Future<List<CityResponse>> loadForDropdown() async {
    final result = await _baseProvider.get<PageResult<CityResponse>>(
      ApiConstants.cities,
      token: _token,
      queryParameters: {'pageSize': 100},
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => CityResponse.fromJson(item),
      ),
    );
    return result.items;
  }

  Future<CityResponse> getById(int id) async {
    return await _baseProvider.get<CityResponse>(
      '${ApiConstants.cities}/$id',
      token: _token,
      fromJson: (json) => CityResponse.fromJson(json),
    );
  }

  Future<void> insert(CityRequest request) async {
    await _baseProvider.post<CityResponse>(
      ApiConstants.cities,
      token: _token,
      data: request.toJson(),
      fromJson: (json) => CityResponse.fromJson(json),
    );
  }

  Future<void> update(int id, CityRequest request) async {
    await _baseProvider.put<CityResponse>(
      '${ApiConstants.cities}/$id',
      token: _token,
      data: request.toJson(),
      fromJson: (json) => CityResponse.fromJson(json),
    );
  }

  Future<void> delete(int id) async {
    await _baseProvider.delete(
      '${ApiConstants.cities}/$id',
      token: _token,
    );
  }

  void setPage(int page) {
    currentPage = page;
  }
}
