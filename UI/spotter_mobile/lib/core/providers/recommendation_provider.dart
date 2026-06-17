import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/recommendation_response.dart';

class RecommendationProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;

  List<RecommendationResponse> recommendations = [];
  bool isLoading = false;
  String? error;

  RecommendationProvider(this._baseProvider);

  Future<void> loadRecommendations() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<List<RecommendationResponse>>(
        ApiConstants.recommendations,
        fromJson: (json) => (json as List)
            .map((item) => RecommendationResponse.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
      recommendations = result;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      recommendations = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    recommendations = [];
    error = null;
    notifyListeners();
  }
}
