import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/reservation_response.dart';
import '../models/page_result.dart';

class ReservationProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<ReservationResponse> items = [];
  int currentPage = 1;
  int pageSize = 10;
  int? totalCount;
  bool isLoading = false;
  String? error;

  ReservationProvider(this._baseProvider, this._authProvider);

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
        'includeTotalCount': true,
      };
      if (eventId != null) {
        queryParams['eventId'] = eventId;
      }
      if (status != null) {
        queryParams['status'] = status;
      }

      final result = await _baseProvider.get<PageResult<ReservationResponse>>(
        ApiConstants.reservations,
        token: _token,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => ReservationResponse.fromJson(item),
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

  Future<ReservationResponse> getById(int id) async {
    return await _baseProvider.get<ReservationResponse>(
      '${ApiConstants.reservations}/$id',
      token: _token,
      fromJson: (json) => ReservationResponse.fromJson(json),
    );
  }

  Future<void> confirm(int id, String? auditNote) async {
    await _baseProvider.postAction(
      '${ApiConstants.reservations}/$id/confirm',
      token: _token,
      data: auditNote != null ? {'auditNote': auditNote} : null,
    );
  }

  Future<void> cancel(int id, String? auditNote) async {
    await _baseProvider.postAction(
      '${ApiConstants.reservations}/$id/cancel',
      token: _token,
      data: auditNote != null ? {'auditNote': auditNote} : null,
    );
  }

  Future<void> complete(int id) async {
    await _baseProvider.postAction(
      '${ApiConstants.reservations}/$id/complete',
      token: _token,
    );
  }

  Future<int> getActiveCount() async {
    final result = await _baseProvider.get<PageResult<ReservationResponse>>(
      ApiConstants.reservations,
      token: _token,
      queryParameters: {'status': 0, 'pageSize': 1},
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => ReservationResponse.fromJson(item),
      ),
    );
    return result.totalCount ?? 0;
  }

  void setPage(int page) {
    currentPage = page;
  }
}
