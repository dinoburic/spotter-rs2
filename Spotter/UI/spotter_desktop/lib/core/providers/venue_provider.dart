import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/venue_response.dart';
import '../models/venue_insert_request.dart';
import '../models/venue_update_request.dart';
import '../models/page_result.dart';

class VenueProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<VenueResponse> items = [];
  int currentPage = 1;
  int pageSize = 10;
  int? totalCount;
  bool isLoading = false;
  String? error;

  VenueProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  Future<void> loadAll({String? name, int? cityId}) async {
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
      if (cityId != null) {
        queryParams['cityId'] = cityId;
      }

      final result = await _baseProvider.get<PageResult<VenueResponse>>(
        ApiConstants.venues,
        token: _token,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => VenueResponse.fromJson(item),
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

  Future<List<VenueResponse>> loadForDropdown() async {
    final result = await _baseProvider.get<PageResult<VenueResponse>>(
      ApiConstants.venues,
      token: _token,
      queryParameters: {'pageSize': 100},
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => VenueResponse.fromJson(item),
      ),
    );
    return result.items;
  }

  Future<VenueResponse> getById(int id) async {
    return await _baseProvider.get<VenueResponse>(
      '${ApiConstants.venues}/$id',
      token: _token,
      fromJson: (json) => VenueResponse.fromJson(json),
    );
  }

  Future<void> insert(VenueInsertRequest request) async {
    await _baseProvider.post<VenueResponse>(
      ApiConstants.venues,
      token: _token,
      data: request.toJson(),
      fromJson: (json) => VenueResponse.fromJson(json),
    );
  }

  Future<void> update(int id, VenueUpdateRequest request) async {
    await _baseProvider.put<VenueResponse>(
      '${ApiConstants.venues}/$id',
      token: _token,
      data: request.toJson(),
      fromJson: (json) => VenueResponse.fromJson(json),
    );
  }

  Future<void> delete(int id) async {
    await _baseProvider.delete(
      '${ApiConstants.venues}/$id',
      token: _token,
    );
  }

  void setPage(int page) {
    currentPage = page;
  }
}
