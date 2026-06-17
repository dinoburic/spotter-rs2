import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/favorite_response.dart';
import '../models/page_result.dart';

class FavoriteProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  List<FavoriteResponse> favorites = [];
  Set<int> favoriteEventIds = {};
  int currentPage = 1;
  final int pageSize = 20;
  bool hasMore = true;
  bool isLoading = false;
  String? error;

  FavoriteProvider(this._baseProvider);

  Future<void> loadFavorites({bool refresh = false}) async {
    if (isLoading) return;

    if (refresh) {
      currentPage = 1;
      hasMore = true;
      favorites.clear();
    }

    if (!hasMore) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<FavoriteResponse>>(
        ApiConstants.favorites,
        queryParameters: {'page': currentPage, 'pageSize': pageSize},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => FavoriteResponse.fromJson(item),
        ),
      );
      favorites.addAll(result.items);
      hasMore = result.totalCount == null
          ? result.items.length >= pageSize
          : favorites.length < result.totalCount!;
      currentPage++;
      favoriteEventIds = favorites.map((f) => f.eventId).toSet();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool isFavorite(int eventId) {
    return favoriteEventIds.contains(eventId);
  }

  Future<bool> toggleFavorite(int eventId) async {
    try {
      if (isFavorite(eventId)) {
        await _baseProvider.delete('${ApiConstants.favorites}/$eventId');
        favoriteEventIds.remove(eventId);
        favorites.removeWhere((f) => f.eventId == eventId);
      } else {
        await _baseProvider.postAction('${ApiConstants.favorites}/$eventId');
        favoriteEventIds.add(eventId);
        await loadFavorites(refresh: true);
      }
      notifyListeners();
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
