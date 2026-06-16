import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/ticket_type_response.dart';
import '../models/ticket_type_insert_request.dart';
import '../models/ticket_type_update_request.dart';
import '../models/page_result.dart';

class TicketTypeProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<TicketTypeResponse> items = [];
  int currentPage = 1;
  int pageSize = 10;
  int? totalCount;
  bool isLoading = false;
  String? error;

  TicketTypeProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  Future<void> loadAll({String? name, int? eventId}) async {
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
      if (eventId != null) {
        queryParams['eventId'] = eventId;
      }

      final result = await _baseProvider.get<PageResult<TicketTypeResponse>>(
        ApiConstants.ticketTypes,
        token: _token,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => TicketTypeResponse.fromJson(item),
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

  Future<TicketTypeResponse> getById(int id) async {
    return await _baseProvider.get<TicketTypeResponse>(
      '${ApiConstants.ticketTypes}/$id',
      token: _token,
      fromJson: (json) => TicketTypeResponse.fromJson(json),
    );
  }

  Future<void> insert(TicketTypeInsertRequest request) async {
    await _baseProvider.post<TicketTypeResponse>(
      ApiConstants.ticketTypes,
      token: _token,
      data: request.toJson(),
      fromJson: (json) => TicketTypeResponse.fromJson(json),
    );
  }

  Future<void> update(int id, TicketTypeUpdateRequest request) async {
    await _baseProvider.put<TicketTypeResponse>(
      '${ApiConstants.ticketTypes}/$id',
      token: _token,
      data: request.toJson(),
      fromJson: (json) => TicketTypeResponse.fromJson(json),
    );
  }

  Future<void> delete(int id) async {
    await _baseProvider.delete(
      '${ApiConstants.ticketTypes}/$id',
      token: _token,
    );
  }

  void setPage(int page) {
    currentPage = page;
  }
}
