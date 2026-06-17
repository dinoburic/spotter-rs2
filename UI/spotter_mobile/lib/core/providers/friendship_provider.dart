import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/user_suggestion_response.dart';
import '../models/friendship_response.dart';
import '../models/page_result.dart';

class FriendshipProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;

  List<UserSuggestionResponse> friends = [];
  List<FriendshipResponse> pendingRequests = [];
  List<UserSuggestionResponse> suggestions = [];
  List<UserSuggestionResponse> searchResults = [];

  bool isLoading = false;
  bool isSearching = false;
  String? error;

  final Set<int> _pendingActionIds = {};

  FriendshipProvider(this._baseProvider);

  Future<void> loadFriends({bool refresh = false}) async {
    if (refresh) friends = [];
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<UserSuggestionResponse>>(
        '${ApiConstants.friendships}/friends',
        queryParameters: {'page': 1, 'pageSize': 100},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => UserSuggestionResponse.fromJson(item),
        ),
      );
      friends = result.items;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingRequests({bool refresh = false}) async {
    if (refresh) pendingRequests = [];
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<FriendshipResponse>>(
        '${ApiConstants.friendships}/pending',
        queryParameters: {'page': 1, 'pageSize': 100},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => FriendshipResponse.fromJson(item),
        ),
      );
      pendingRequests = result.items;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSuggestions({bool refresh = false}) async {
    if (refresh) suggestions = [];
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<UserSuggestionResponse>>(
        '${ApiConstants.friendships}/suggestions',
        queryParameters: {'page': 1, 'pageSize': 10},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => UserSuggestionResponse.fromJson(item),
        ),
      );
      suggestions = result.items;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }

    isSearching = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<UserSuggestionResponse>>(
        '${ApiConstants.friendships}/search',
        queryParameters: {'query': query, 'page': 1, 'pageSize': 20},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => UserSuggestionResponse.fromJson(item),
        ),
      );
      searchResults = result.items;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    searchResults = [];
    notifyListeners();
  }

  bool isPendingAction(int userId) => _pendingActionIds.contains(userId);

  Future<bool> sendRequest(int userId) async {
    _pendingActionIds.add(userId);
    notifyListeners();

    try {
      await _baseProvider.postAction(
        '${ApiConstants.friendships}/request/$userId',
      );
      suggestions.removeWhere((s) => s.userId == userId);
      searchResults.removeWhere((s) => s.userId == userId);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _pendingActionIds.remove(userId);
      notifyListeners();
    }
  }

  Future<bool> acceptRequest(int friendshipId) async {
    try {
      await _baseProvider.postAction(
        '${ApiConstants.friendships}/$friendshipId/accept',
      );
      pendingRequests.removeWhere((r) => r.id == friendshipId);
      await loadFriends(refresh: true);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRequest(int friendshipId) async {
    try {
      await _baseProvider.postAction(
        '${ApiConstants.friendships}/$friendshipId/reject',
      );
      pendingRequests.removeWhere((r) => r.id == friendshipId);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFriend(int friendshipId) async {
    try {
      await _baseProvider.delete('${ApiConstants.friendships}/$friendshipId');
      await loadFriends(refresh: true);
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
