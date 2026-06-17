import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  LoginResponse? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthProvider() : _baseProvider = BaseProvider();

  LoginResponse? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  String? get token => _currentUser?.accessToken;
  bool get isAdmin => _currentUser?.role == 'Admin';
  String get username => _currentUser?.username ?? '';
  String get role => _currentUser?.role ?? '';

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = LoginRequest(username: username, password: password);
      final response = await _baseProvider.post<LoginResponse>(
        ApiConstants.login,
        data: request.toJson(),
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      if (response.role != 'Admin') {
        _error = 'Access denied. Only administrators can access this panel.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', response.accessToken);
      await prefs.setString('refreshToken', response.refreshToken);
      await prefs.setString('role', response.role);
      await prefs.setString('username', response.username);
      await prefs.setInt('userId', response.userId);

      _currentUser = response;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final role = prefs.getString('role');

    if (token == null || token.isEmpty) return;
    if (role == null || role != 'Admin') {
      await prefs.clear();
      return;
    }

    final refreshToken = prefs.getString('refreshToken') ?? '';
    final username = prefs.getString('username') ?? '';
    final userId = prefs.getInt('userId') ?? 0;

    _currentUser = LoginResponse(
      accessToken: token,
      refreshToken: refreshToken,
      userId: userId,
      username: username,
      role: role,
    );
    notifyListeners();
  }

  Future<void> logout() async {
    if (_currentUser == null) return;

    try {
      await _baseProvider.postAction(
        ApiConstants.logout,
        token: _currentUser!.accessToken,
        data: {'refreshToken': _currentUser!.refreshToken},
      );
    } catch (_) {
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _currentUser = null;
      _error = null;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
