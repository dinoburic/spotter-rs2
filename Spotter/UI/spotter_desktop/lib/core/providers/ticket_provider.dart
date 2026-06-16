import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/ticket_response.dart';
import '../models/page_result.dart';

class TicketProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<TicketResponse> items = [];
  int currentPage = 1;
  int pageSize = 10;
  int? totalCount;
  bool isLoading = false;
  String? error;

  TicketProvider(this._baseProvider, this._authProvider);

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

      final result = await _baseProvider.get<PageResult<TicketResponse>>(
        ApiConstants.tickets,
        token: _token,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => TicketResponse.fromJson(item),
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

  Future<TicketResponse> getById(int id) async {
    return await _baseProvider.get<TicketResponse>(
      '${ApiConstants.tickets}/$id',
      token: _token,
      fromJson: (json) => TicketResponse.fromJson(json),
    );
  }

  Future<void> useTicket(String qrCodePayload) async {
    await _baseProvider.post<void>(
      '${ApiConstants.tickets}/use',
      token: _token,
      data: {'qrCodePayload': qrCodePayload},
      fromJson: (_) {},
    );
  }

  Future<List<TicketResponse>> getUsedTicketsForEvent(int eventId) async {
    final result = await _baseProvider.get<PageResult<TicketResponse>>(
      ApiConstants.tickets,
      token: _token,
      queryParameters: {'eventId': eventId, 'status': 1, 'pageSize': 100},
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => TicketResponse.fromJson(item),
      ),
    );
    return result.items;
  }

  Future<List<TicketResponse>> loadForGuestList(int eventId) async {
    final result = await _baseProvider.get<PageResult<TicketResponse>>(
      ApiConstants.tickets,
      token: _token,
      queryParameters: {
        'eventId': eventId,
        'pageSize': 200,
      },
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => TicketResponse.fromJson(item),
      ),
    );
    return result.items;
  }

  void setPage(int page) {
    currentPage = page;
  }
}
