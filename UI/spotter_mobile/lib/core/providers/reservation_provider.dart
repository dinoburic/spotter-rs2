import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/reservation_response.dart';
import '../models/reservation_insert_request.dart';
import '../models/page_result.dart';

class ReservationProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  List<ReservationResponse> reservations = [];
  int currentPage = 1;
  final int pageSize = 20;
  bool hasMore = true;
  bool isLoading = false;
  String? error;

  ReservationProvider(this._baseProvider);

  Future<void> loadReservations({bool refresh = false}) async {
    if (isLoading) return;

    if (refresh) {
      currentPage = 1;
      hasMore = true;
      reservations.clear();
    }

    if (!hasMore) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<ReservationResponse>>(
        ApiConstants.reservations,
        queryParameters: {'page': currentPage, 'pageSize': pageSize},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => ReservationResponse.fromJson(item),
        ),
      );
      reservations.addAll(result.items);
      hasMore = result.totalCount == null
          ? result.items.length >= pageSize
          : reservations.length < result.totalCount!;
      currentPage++;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ReservationResponse?> createReservation(
    ReservationInsertRequest request,
  ) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final reservation = await _baseProvider.post<ReservationResponse>(
        ApiConstants.reservations,
        data: request.toJson(),
        fromJson: (json) => ReservationResponse.fromJson(json),
      );
      reservations.insert(0, reservation);
      notifyListeners();
      return reservation;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelReservation(int id) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _baseProvider.postAction('${ApiConstants.reservations}/$id/cancel');
      isLoading = false;
      await loadReservations(refresh: true);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
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
