import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/review_response.dart';
import '../models/review_insert_request.dart';
import '../models/page_result.dart';

class ReviewProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  List<ReviewResponse> reviews = [];
  bool isLoading = false;
  String? error;

  ReviewProvider(this._baseProvider);

  Future<void> loadReviewsForEvent(int eventId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<ReviewResponse>>(
        ApiConstants.reviews,
        queryParameters: {
          'page': 1,
          'pageSize': 100,
          'eventId': eventId,
        },
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => ReviewResponse.fromJson(item),
        ),
      );
      reviews = result.items;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ReviewResponse?> createReview(ReviewInsertRequest request) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final review = await _baseProvider.post<ReviewResponse>(
        ApiConstants.reviews,
        data: request.toJson(),
        fromJson: (json) => ReviewResponse.fromJson(json),
      );
      reviews.insert(0, review);
      notifyListeners();
      return review;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
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
