import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/user_response.dart';
import '../models/user_update_request.dart';
import '../models/badge_response.dart';
import '../models/points_response.dart';
import '../models/city_response.dart';
import '../models/page_result.dart';

class ProfileProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  UserResponse? profile;
  List<UserBadgeResponse> badges = [];
  PointsBalanceResponse? pointsBalance;
  List<CityResponse> cities = [];
  bool isLoading = false;
  String? error;

  ProfileProvider(this._baseProvider);

  Future<void> loadProfile(int userId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      profile = await _baseProvider.get<UserResponse>(
        '${ApiConstants.users}/$userId',
        fromJson: (json) => UserResponse.fromJson(json),
      );
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBadges(int userId) async {
    try {
      final result = await _baseProvider.get<PageResult<UserBadgeResponse>>(
        '${ApiConstants.badges}/user/$userId',
        queryParameters: {'page': 1, 'pageSize': 100},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => UserBadgeResponse.fromJson(item),
        ),
      );
      badges = result.items;
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadPointsBalance() async {
    try {
      pointsBalance = await _baseProvider.get<PointsBalanceResponse>(
        '${ApiConstants.points}/balance',
        fromJson: (json) => PointsBalanceResponse.fromJson(json),
      );
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> loadCities() async {
    try {
      final result = await _baseProvider.get<PageResult<CityResponse>>(
        ApiConstants.cities,
        queryParameters: {'page': 1, 'pageSize': 100},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => CityResponse.fromJson(item),
        ),
      );
      cities = result.items;
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> updateProfile(int userId, UserUpdateRequest request) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      profile = await _baseProvider.put<UserResponse>(
        '${ApiConstants.users}/$userId',
        data: request.toJson(),
        fromJson: (json) => UserResponse.fromJson(json),
      );
      notifyListeners();
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
