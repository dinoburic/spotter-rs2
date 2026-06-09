import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/event_response.dart';
import '../models/category_response.dart';
import '../models/ticket_type_response.dart';
import '../models/page_result.dart';

class EventProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  List<EventResponse> items = [];
  List<EventResponse> mapItems = [];
  List<CategoryResponse> categories = [];
  List<TicketTypeResponse> ticketTypes = [];
  int currentPage = 1;
  int pageSize = 10;
  bool hasMore = true;
  bool isLoading = false;
  String? error;
  String? searchQuery;
  int? selectedCategoryId;

  EventProvider(this._baseProvider);

  Future<void> loadEvents({bool refresh = false}) async {
    if (isLoading) return;

    if (refresh) {
      currentPage = 1;
      hasMore = true;
      items.clear();
    }

    if (!hasMore) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': currentPage,
        'pageSize': pageSize,
        'status': 1,
      };
      if (searchQuery != null && searchQuery!.isNotEmpty) {
        queryParams['title'] = searchQuery;
      }
      if (selectedCategoryId != null) {
        queryParams['categoryId'] = selectedCategoryId;
      }

      final result = await _baseProvider.get<PageResult<EventResponse>>(
        ApiConstants.events,
        queryParameters: queryParams,
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => EventResponse.fromJson(item),
        ),
      );

      items.addAll(result.items);
      hasMore = result.items.length >= pageSize;
      currentPage++;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMapEvents() async {
    try {
      final result = await _baseProvider.get<PageResult<EventResponse>>(
        ApiConstants.events,
        queryParameters: {
          'page': 1,
          'pageSize': 100,
          'status': 1,
        },
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => EventResponse.fromJson(item),
        ),
      );
      mapItems = result.items
          .where((e) => e.venueLatitude != null && e.venueLongitude != null)
          .toList();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<EventResponse?> getEventById(int id) async {
    try {
      return await _baseProvider.get<EventResponse>(
        '${ApiConstants.events}/$id',
        fromJson: (json) => EventResponse.fromJson(json),
      );
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> loadCategories() async {
    try {
      final result = await _baseProvider.get<PageResult<CategoryResponse>>(
        ApiConstants.categories,
        queryParameters: {'page': 1, 'pageSize': 100},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => CategoryResponse.fromJson(item),
        ),
      );
      categories = result.items;
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadTicketTypes(int eventId) async {
    try {
      final result = await _baseProvider.get<PageResult<TicketTypeResponse>>(
        ApiConstants.ticketTypes,
        queryParameters: {
          'page': 1,
          'pageSize': 100,
          'eventId': eventId,
        },
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => TicketTypeResponse.fromJson(item),
        ),
      );
      ticketTypes = result.items;
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void setSearchQuery(String? query) {
    searchQuery = query;
    loadEvents(refresh: true);
  }

  void setSelectedCategory(int? categoryId) {
    selectedCategoryId = categoryId;
    loadEvents(refresh: true);
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
