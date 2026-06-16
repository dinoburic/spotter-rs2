import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/event_response.dart';
import '../models/category_response.dart';
import '../models/ticket_type_response.dart';
import '../models/venue_response.dart';
import '../models/page_result.dart';

class EventProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  List<EventResponse> items = [];
  List<EventResponse> mapItems = [];
  List<EventResponse> myEvents = [];
  List<CategoryResponse> categories = [];
  List<VenueResponse> venues = [];
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

  Future<void> loadVenues() async {
    try {
      final result = await _baseProvider.get<PageResult<VenueResponse>>(
        ApiConstants.venues,
        queryParameters: {'page': 1, 'pageSize': 100},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => VenueResponse.fromJson(item),
        ),
      );
      venues = result.items;
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<int?> createEvent(Map<String, dynamic> request) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.post<Map<String, dynamic>>(
        ApiConstants.events,
        data: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );
      isLoading = false;
      notifyListeners();
      return result['id'] as int?;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> createTicketType(Map<String, dynamic> request) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _baseProvider.post<Map<String, dynamic>>(
        ApiConstants.ticketTypes,
        data: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMyEvents(int organizerId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<EventResponse>>(
        ApiConstants.events,
        queryParameters: {
          'organizerId': organizerId,
          'pageSize': 100,
        },
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => EventResponse.fromJson(item),
        ),
      );
      myEvents = result.items;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEvent(int id, Map<String, dynamic> request) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _baseProvider.put<Map<String, dynamic>>(
        '${ApiConstants.events}/$id',
        data: request,
        fromJson: (json) => json as Map<String, dynamic>,
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> activateEvent(int id) async {
    try {
      await _baseProvider.post<Map<String, dynamic>>(
        '${ApiConstants.events}/$id/activate',
        fromJson: (json) => json as Map<String, dynamic>,
      );
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelEvent(int id) async {
    try {
      await _baseProvider.post<Map<String, dynamic>>(
        '${ApiConstants.events}/$id/cancel',
        fromJson: (json) => json as Map<String, dynamic>,
      );
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEvent(int id) async {
    try {
      await _baseProvider.delete('${ApiConstants.events}/$id');
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
