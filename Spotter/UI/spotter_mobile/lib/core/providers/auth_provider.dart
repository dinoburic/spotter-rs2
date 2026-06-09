import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/login_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

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
  bool get isUser => _currentUser?.role == 'User';
  String get username => _currentUser?.username ?? '';
  String get role => _currentUser?.role ?? '';
  int get userId => _currentUser?.userId ?? 0;

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

      _currentUser = response;
      _baseProvider.setToken(response.accessToken);
      await _saveToStorage(response);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(RegisterRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _baseProvider.post<LoginResponse>(
        ApiConstants.register,
        data: request.toJson(),
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      _currentUser = response;
      _baseProvider.setToken(response.accessToken);
      await _saveToStorage(response);
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_currentUser == null) return;

    try {
      await _baseProvider.postAction(
        ApiConstants.logout,
        data: {'refreshToken': _currentUser!.refreshToken},
      );
    } catch (_) {
    } finally {
      _currentUser = null;
      _baseProvider.setToken(null);
      await _clearStorage();
      _error = null;
      notifyListeners();
    }
  }

  Future<void> tryAutoLogin() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');
    final userId = prefs.getInt('userId');
    final username = prefs.getString('username');
    final role = prefs.getString('role');

    if (accessToken != null &&
        refreshToken != null &&
        userId != null &&
        username != null &&
        role != null) {
      _currentUser = LoginResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        username: username,
        role: role,
      );
      _baseProvider.setToken(accessToken);
      notifyListeners();
    }
  } catch (_) {}
}

  Future<void> _saveToStorage(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', response.accessToken);
    await prefs.setString('refreshToken', response.refreshToken);
    await prefs.setInt('userId', response.userId);
    await prefs.setString('username', response.username);
    await prefs.setString('role', response.role);
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('userId');
    await prefs.remove('username');
    await prefs.remove('role');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  BaseProvider get baseProvider => _baseProvider;
}
