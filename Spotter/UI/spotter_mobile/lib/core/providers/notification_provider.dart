import 'dart:async';
import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/notification_response.dart';
import '../models/page_result.dart';
import 'auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;
  List<NotificationResponse> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;
  String? error;
  Timer? _pollTimer;


  NotificationProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadUnreadCount();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> loadNotifications() async {
  if (_authProvider?.token == null) return;
  isLoading = true;
  error = null;
  notifyListeners();

  try {
    final result = await _baseProvider.get<PageResult<NotificationResponse>>(
      ApiConstants.notifications,
      queryParameters: {'page': 1, 'pageSize': 100},
      fromJson: (json) => PageResult.fromJson(
        json,
        (item) => NotificationResponse.fromJson(item),
      ),
    );
    notifications = result.items;
    unreadCount = notifications.where((n) => !n.isRead).length;
  } catch (e) {
    error = e.toString().replaceAll('Exception: ', '');
  } finally {
    isLoading = false;
    notifyListeners();
  }
}

  Future<void> loadUnreadCount() async {
  if (_authProvider?.token == null) return;
  try {
    final result = await _baseProvider.get<Map<String, dynamic>>(
      '${ApiConstants.notifications}/unread-count',
      fromJson: (json) => json as Map<String, dynamic>,
    );
    unreadCount = result['count'] as int? ?? 0;
    notifyListeners();
  } catch (_) {}
}

  Future<void> markAsRead(int id) async {
    try {
      await _baseProvider.postAction('${ApiConstants.notifications}/$id/read');
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !notifications[index].isRead) {
        unreadCount--;
        notifications[index] = NotificationResponse(
          id: notifications[index].id,
          userId: notifications[index].userId,
          title: notifications[index].title,
          body: notifications[index].body,
          type: notifications[index].type,
          typeName: notifications[index].typeName,
          referenceId: notifications[index].referenceId,
          isRead: true,
          createdAt: notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _baseProvider.postAction('${ApiConstants.notifications}/mark-all-read');
      for (var i = 0; i < notifications.length; i++) {
        notifications[i] = NotificationResponse(
          id: notifications[i].id,
          userId: notifications[i].userId,
          title: notifications[i].title,
          body: notifications[i].body,
          type: notifications[i].type,
          typeName: notifications[i].typeName,
          referenceId: notifications[i].referenceId,
          isRead: true,
          createdAt: notifications[i].createdAt,
        );
      }
      unreadCount = 0;
      notifyListeners();
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
