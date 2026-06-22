import 'package:flutter/material.dart';
import 'base_provider.dart';
import 'auth_provider.dart';
import '../constants/api_constants.dart';
import '../models/system_setting_response.dart';
import '../models/system_setting_update_request.dart';

class SystemSettingProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;

  List<SystemSettingResponse> items = [];
  bool isLoading = false;
  String? error;

  SystemSettingProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<List<SystemSettingResponse>>(
        ApiConstants.systemSettings,
        token: _token,
        fromJson: (json) => (json as List)
            .map((item) => SystemSettingResponse.fromJson(item))
            .toList(),
      );

      items = result;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> update(String key, SystemSettingUpdateRequest request) async {
    await _baseProvider.put<SystemSettingResponse>(
      '${ApiConstants.systemSettings}/$key',
      token: _token,
      data: request.toJson(),
      fromJson: (json) => SystemSettingResponse.fromJson(json),
    );
  }
}
