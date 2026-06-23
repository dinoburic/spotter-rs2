import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/event_response.dart';
import '../models/event_insert_request.dart';
import '../models/event_update_request.dart';
import '../models/ticket_type_response.dart';
import '../models/page_result.dart';

class EventProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<EventResponse> items = [];
  int currentPage = 1;
  int pageSize = 10;
  int? totalCount;
  bool isLoading = false;
  String? error;

  EventProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  Future<void> loadAll({String? title, int? categoryId, int? status}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': currentPage,
        'pageSize': pageSize,
        'includeTotalCount': true,
      };
      if (title != null && title.isNotEmpty) {
        queryParams['title'] = title;
      }
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }
      if (status != null) {
        queryParams['status'] = status;
      }

      final result = await _baseProvider.get<PageResult<EventResponse>>(
        ApiConstants.events,
        token: _token,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => EventResponse.fromJson(item),
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

  Future<List<EventResponse>> loadForDropdown() async {
    final result = await _baseProvider.get<PageResult<EventResponse>>(
      ApiConstants.events,
      token: _token,
      queryParameters: {'pageSize': 100},
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => EventResponse.fromJson(item),
      ),
    );
    return result.items;
  }

  Future<EventResponse> getById(int id) async {
    return await _baseProvider.get<EventResponse>(
      '${ApiConstants.events}/$id',
      token: _token,
      fromJson: (json) => EventResponse.fromJson(json),
    );
  }

  Future<EventResponse> insert(EventInsertRequest request) async {
    return await _baseProvider.post<EventResponse>(
      ApiConstants.events,
      token: _token,
      data: request.toJson(),
      fromJson: (json) => EventResponse.fromJson(json),
    );
  }

  Future<void> update(int id, EventUpdateRequest request) async {
    await _baseProvider.put<EventResponse>(
      '${ApiConstants.events}/$id',
      token: _token,
      data: request.toJson(),
      fromJson: (json) => EventResponse.fromJson(json),
    );
  }

  Future<void> delete(int id) async {
    await _baseProvider.delete(
      '${ApiConstants.events}/$id',
      token: _token,
    );
  }

  List<dynamic> ticketTypes = [];

Future<void> loadTicketTypes(int eventId) async {
  try {
    final result = await _baseProvider.get<PageResult<TicketTypeResponse>>(
      ApiConstants.ticketTypes,
      token: _token,
      queryParameters: {'eventId': eventId, 'pageSize': 100},
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => TicketTypeResponse.fromJson(item),
      ),
    );
    ticketTypes = result.items;
    notifyListeners();
  } catch (e) {
    error = e.toString();
  }
}

  Future<void> activate(int id) async {
    await _baseProvider.postAction(
      '${ApiConstants.events}/$id/activate',
      token: _token,
    );
  }

  Future<void> cancel(int id) async {
    await _baseProvider.postAction(
      '${ApiConstants.events}/$id/cancel',
      token: _token,
    );
  }

  Future<void> complete(int id) async {
    await _baseProvider.postAction(
      '${ApiConstants.events}/$id/complete',
      token: _token,
    );
  }

  Future<String?> uploadCoverImage(int eventId, String filePath) async {
    try {
      final result = await _baseProvider.uploadFile<Map<String, dynamic>>(
        '${ApiConstants.events}/$eventId/cover-image',
        filePath,
        'file',
        token: _token,
        fromJson: (json) => json as Map<String, dynamic>,
      );
      return result['url'] as String?;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void setPage(int page) {
    currentPage = page;
  }
}
