import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../models/organizer_dashboard_response.dart';

class OrganizerProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;

  OrganizerDashboardResponse? dashboard;
  bool isLoading = false;
  String? error;

  OrganizerProvider(this._baseProvider);

  Future<void> loadDashboard() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      dashboard = await _baseProvider.get<OrganizerDashboardResponse>(
        '/api/organizer/dashboard',
        fromJson: (json) => OrganizerDashboardResponse.fromJson(json),
      );
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
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
