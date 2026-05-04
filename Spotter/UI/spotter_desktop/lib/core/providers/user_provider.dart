import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/user_response.dart';
import '../models/user_insert_request.dart';
import '../models/user_update_request.dart';
import '../models/page_result.dart';

class UserProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<UserResponse> items = [];
  int currentPage = 1;
  int pageSize = 10;
  int? totalCount;
  bool isLoading = false;
  String? error;

  UserProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  Future<void> loadAll({String? username, String? role}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': currentPage,
        'pageSize': pageSize,
      };
      if (username != null && username.isNotEmpty) {
        queryParams['username'] = username;
      }
      if (role != null && role.isNotEmpty) {
        queryParams['role'] = role;
      }

      final result = await _baseProvider.get<PageResult<UserResponse>>(
        ApiConstants.users,
        token: _token,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => UserResponse.fromJson(item),
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

  Future<UserResponse> getById(int id) async {
    return await _baseProvider.get<UserResponse>(
      '${ApiConstants.users}/$id',
      token: _token,
      fromJson: (json) => UserResponse.fromJson(json),
    );
  }

  Future<void> insert(UserInsertRequest request) async {
    await _baseProvider.post<UserResponse>(
      ApiConstants.users,
      token: _token,
      data: request.toJson(),
      fromJson: (json) => UserResponse.fromJson(json),
    );
  }

  Future<void> update(int id, UserUpdateRequest request) async {
    await _baseProvider.put<UserResponse>(
      '${ApiConstants.users}/$id',
      token: _token,
      data: request.toJson(),
      fromJson: (json) => UserResponse.fromJson(json),
    );
  }

  Future<void> delete(int id) async {
    await _baseProvider.delete(
      '${ApiConstants.users}/$id',
      token: _token,
    );
  }

  void setPage(int page) {
    currentPage = page;
  }
}
