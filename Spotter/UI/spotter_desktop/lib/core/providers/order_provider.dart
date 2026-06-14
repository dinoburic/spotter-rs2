import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/order_response.dart';
import '../models/page_result.dart';

class OrderProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<OrderResponse> items = [];
  int currentPage = 1;
  int pageSize = 10;
  int? totalCount;
  bool isLoading = false;
  String? error;

  OrderProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  Future<void> loadAll({int? eventId, int? status}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': currentPage,
        'pageSize': pageSize,
      };
      if (eventId != null) {
        queryParams['eventId'] = eventId;
      }
      if (status != null) {
        queryParams['status'] = status;
      }

      final result = await _baseProvider.get<PageResult<OrderResponse>>(
        ApiConstants.orders,
        token: _token,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => OrderResponse.fromJson(item),
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

  Future<OrderResponse> getById(int id) async {
    return await _baseProvider.get<OrderResponse>(
      '${ApiConstants.orders}/$id',
      token: _token,
      fromJson: (json) => OrderResponse.fromJson(json),
    );
  }

  Future<void> markAsPaid(int id) async {
    await _baseProvider.postAction(
      '${ApiConstants.orders}/$id/pay',
      token: _token,
    );
  }

  Future<void> refund(int id) async {
    await _baseProvider.postAction(
      '${ApiConstants.orders}/$id/refund',
      token: _token,
    );
  }

  Future<int> getCountByStatus(int status) async {
    final result = await _baseProvider.get<PageResult<OrderResponse>>(
      ApiConstants.orders,
      token: _token,
      queryParameters: {'status': status, 'pageSize': 1},
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => OrderResponse.fromJson(item),
      ),
    );
    return result.totalCount ?? 0;
  }

  void setPage(int page) {
    currentPage = page;
  }

  Future<List<OrderResponse>> loadForReport({
    DateTime? from,
    DateTime? to,
    int? categoryId,
  }) async {
    final result = await _baseProvider.get<PageResult<OrderResponse>>(
      ApiConstants.orders,
      token: _token,
      queryParameters: {
        'status': 1,
        'pageSize': 100,
      },
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => OrderResponse.fromJson(item),
      ),
    );

    var filtered = result.items;

    if (from != null) {
      filtered = filtered
          .where((o) => o.createdAt.isAfter(from.subtract(const Duration(days: 1))))
          .toList();
    }
    if (to != null) {
      filtered = filtered
          .where((o) => o.createdAt.isBefore(to.add(const Duration(days: 1))))
          .toList();
    }

    return filtered;
  }
}
