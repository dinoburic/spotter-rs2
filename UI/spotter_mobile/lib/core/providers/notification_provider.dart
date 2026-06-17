import 'package:flutter/material.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/notification_response.dart';
import '../models/page_result.dart';
import '../services/signalr_service.dart';
import 'auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  AuthProvider? _authProvider;
  final SignalRService _signalRService = SignalRService();
  List<NotificationResponse> notifications = [];
  int unreadCount = 0;
  int currentPage = 1;
  final int pageSize = 20;
  bool hasMore = true;
  bool isLoading = false;
  String? error;

  NotificationProvider(this._baseProvider, this._authProvider);

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
  }

  String? get _token => _authProvider?.token;

  Future<void> startRealtime() async {
    if (_token == null) return;

    _signalRService.onNotificationReceived = (data) {
      final notification = NotificationResponse.fromJson(data);
      notifications.insert(0, notification);
      unreadCount++;
      notifyListeners();
    };

    await _signalRService.startConnection(_token!);
  }

  Future<void> stopRealtime() async {
    await _signalRService.stopConnection();
  }

  void startPolling() {
    startRealtime();
  }

  void stopPolling() {
    stopRealtime();
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (_authProvider?.token == null) return;
    if (isLoading) return;

    if (refresh) {
      currentPage = 1;
      hasMore = true;
      notifications.clear();
    }

    if (!hasMore) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _baseProvider.get<PageResult<NotificationResponse>>(
        ApiConstants.notifications,
        queryParameters: {'page': currentPage, 'pageSize': pageSize},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => NotificationResponse.fromJson(item),
        ),
      );
      notifications.addAll(result.items);
      hasMore = result.totalCount == null
          ? result.items.length >= pageSize
          : notifications.length < result.totalCount!;
      currentPage++;
      await _loadUnreadCount(notify: false);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    if (_authProvider?.token == null) return;
    await _loadUnreadCount();
  }

  Future<void> _loadUnreadCount({bool notify = true}) async {
    try {
      final result = await _baseProvider.get<Map<String, dynamic>>(
        '${ApiConstants.notifications}/unread-count',
        fromJson: (json) => json as Map<String, dynamic>,
      );
      unreadCount = result['count'] as int? ?? 0;
      if (notify) {
        notifyListeners();
      }
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
      await _baseProvider.postAction('${ApiConstants.notifications}/read-all');
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
    _signalRService.stopConnection();
    super.dispose();
  }
}
