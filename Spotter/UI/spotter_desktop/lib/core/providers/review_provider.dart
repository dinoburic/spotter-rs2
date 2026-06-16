import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/review_response.dart';
import '../models/page_result.dart';

class ReviewProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<ReviewResponse> items = [];
  int currentPage = 1;
  int pageSize = 10;
  int? totalCount;
  bool isLoading = false;
  String? error;

  ReviewProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  Future<void> loadAll({int? eventId, int? rating}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': currentPage,
        'pageSize': pageSize,
        'includeTotalCount': true,
      };
      if (eventId != null) {
        queryParams['eventId'] = eventId;
      }
      if (rating != null) {
        queryParams['rating'] = rating;
      }

      final result = await _baseProvider.get<PageResult<ReviewResponse>>(
        ApiConstants.reviews,
        token: _token,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => ReviewResponse.fromJson(item),
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

  Future<ReviewResponse> getById(int id) async {
    return await _baseProvider.get<ReviewResponse>(
      '${ApiConstants.reviews}/$id',
      token: _token,
      fromJson: (json) => ReviewResponse.fromJson(json),
    );
  }

  Future<void> delete(int id) async {
    await _baseProvider.delete(
      '${ApiConstants.reviews}/$id',
      token: _token,
    );
  }

  void setPage(int page) {
    currentPage = page;
  }
}
