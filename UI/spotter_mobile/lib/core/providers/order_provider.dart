import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/order_response.dart';
import '../models/order_insert_request.dart';
import '../models/page_result.dart';

class OrderProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  List<OrderResponse> orders = [];
  int currentPage = 1;
  final int pageSize = 20;
  bool hasMore = true;
  bool isLoading = false;
  String? error;

  OrderProvider(this._baseProvider);

  Future<void> loadOrders({bool refresh = false}) async {
    if (isLoading) return;

    if (refresh) {
      currentPage = 1;
      hasMore = true;
      orders.clear();
    }

    if (!hasMore) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<OrderResponse>>(
        ApiConstants.orders,
        queryParameters: {'page': currentPage, 'pageSize': pageSize},
        fromJson: (json) =>
            PageResult.fromJson(json, (item) => OrderResponse.fromJson(item)),
      );
      orders.addAll(result.items);
      hasMore = result.totalCount == null
          ? result.items.length >= pageSize
          : orders.length < result.totalCount!;
      currentPage++;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderResponse?> getOrderById(int id) async {
    try {
      return await _baseProvider.get<OrderResponse>(
        '${ApiConstants.orders}/$id',
        fromJson: (json) => OrderResponse.fromJson(json),
      );
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<OrderResponse?> createOrder(OrderInsertRequest request) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final order = await _baseProvider.post<OrderResponse>(
        ApiConstants.orders,
        data: request.toJson(),
        fromJson: (json) => OrderResponse.fromJson(json),
      );
      orders.insert(0, order);
      notifyListeners();
      return order;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
