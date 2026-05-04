import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/page_result.dart';
import '../models/event_response.dart';
import '../models/order_response.dart';
import '../models/user_response.dart';
import '../models/reservation_response.dart';

class DashboardProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  int totalEvents = 0;
  int totalOrders = 0;
  int totalUsers = 0;
  int activeReservations = 0;
  int pendingOrders = 0;
  int paidOrders = 0;
  int refundedOrders = 0;
  bool isLoading = false;
  String? error;

  DashboardProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  Future<void> loadStats() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final eventResult = await _baseProvider.get<PageResult<EventResponse>>(
        ApiConstants.events,
        token: _token,
        queryParameters: {'pageSize': 1},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => EventResponse.fromJson(item),
        ),
      );
      totalEvents = eventResult.totalCount ?? 0;

      final orderResult = await _baseProvider.get<PageResult<OrderResponse>>(
        ApiConstants.orders,
        token: _token,
        queryParameters: {'pageSize': 1},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => OrderResponse.fromJson(item),
        ),
      );
      totalOrders = orderResult.totalCount ?? 0;

      final userResult = await _baseProvider.get<PageResult<UserResponse>>(
        ApiConstants.users,
        token: _token,
        queryParameters: {'pageSize': 1},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => UserResponse.fromJson(item),
        ),
      );
      totalUsers = userResult.totalCount ?? 0;

      final reservationResult =
          await _baseProvider.get<PageResult<ReservationResponse>>(
        ApiConstants.reservations,
        token: _token,
        queryParameters: {'status': 0, 'pageSize': 1},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => ReservationResponse.fromJson(item),
        ),
      );
      activeReservations = reservationResult.totalCount ?? 0;

      final pendingResult = await _baseProvider.get<PageResult<OrderResponse>>(
        ApiConstants.orders,
        token: _token,
        queryParameters: {'status': 0, 'pageSize': 1},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => OrderResponse.fromJson(item),
        ),
      );
      pendingOrders = pendingResult.totalCount ?? 0;

      final paidResult = await _baseProvider.get<PageResult<OrderResponse>>(
        ApiConstants.orders,
        token: _token,
        queryParameters: {'status': 1, 'pageSize': 1},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => OrderResponse.fromJson(item),
        ),
      );
      paidOrders = paidResult.totalCount ?? 0;

      final refundedResult = await _baseProvider.get<PageResult<OrderResponse>>(
        ApiConstants.orders,
        token: _token,
        queryParameters: {'status': 2, 'pageSize': 1},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => OrderResponse.fromJson(item),
        ),
      );
      refundedOrders = refundedResult.totalCount ?? 0;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
