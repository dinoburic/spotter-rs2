import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/favorite_response.dart';
import '../models/page_result.dart';

class FavoriteProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  List<FavoriteResponse> favorites = [];
  Set<int> favoriteEventIds = {};
  bool isLoading = false;
  String? error;

  FavoriteProvider(this._baseProvider);

  Future<void> loadFavorites() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<FavoriteResponse>>(
        '${ApiConstants.favorites}/my',
        queryParameters: {'page': 1, 'pageSize': 100},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => FavoriteResponse.fromJson(item),
        ),
      );
      favorites = result.items;
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
        await _baseProvider.postAction(
          ApiConstants.favorites,
          data: {'eventId': eventId},
        );
        favoriteEventIds.add(eventId);
        await loadFavorites();
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
