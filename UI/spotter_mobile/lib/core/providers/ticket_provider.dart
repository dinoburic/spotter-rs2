import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';
import '../constants/api_constants.dart';
import '../models/ticket_response.dart';
import '../models/page_result.dart';

class TicketProvider extends ChangeNotifier {
  final BaseProvider _baseProvider;
  List<TicketResponse> activeTickets = [];
  List<TicketResponse> usedTickets = [];
  List<TicketResponse> cancelledTickets = [];
  final int pageSize = 20;
  bool isLoading = false;
  String? error;
  final Map<int, int> _pages = {0: 1, 1: 1, 2: 1};
  final Map<int, bool> _hasMore = {0: true, 1: true, 2: true};
  final Set<int> _loadingStatuses = {};

  TicketProvider(this._baseProvider);

  bool hasMoreForStatus(int status) => _hasMore[status] ?? false;

  bool isLoadingStatus(int status) => _loadingStatuses.contains(status);

  Future<void> loadTickets({bool refresh = false}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadTicketsByStatus(0, refresh: refresh),
        loadTicketsByStatus(1, refresh: refresh),
        loadTicketsByStatus(2, refresh: refresh),
      ]);
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTicketsByStatus(int status, {bool refresh = false}) async {
    if (_loadingStatuses.contains(status)) return;

    if (refresh) {
      _pages[status] = 1;
      _hasMore[status] = true;
      _ticketsForStatus(status).clear();
    }

    if (!hasMoreForStatus(status)) return;

    _loadingStatuses.add(status);
    error = null;
    notifyListeners();

    try {
      final tickets = _ticketsForStatus(status);
      final result = await _baseProvider.get<PageResult<TicketResponse>>(
        ApiConstants.tickets,
        queryParameters: {
          'page': _pages[status],
          'pageSize': pageSize,
          'status': status,
        },
        fromJson: (json) =>
            PageResult.fromJson(json, (item) => TicketResponse.fromJson(item)),
      );
      tickets.addAll(result.items);
      _hasMore[status] = result.totalCount == null
          ? result.items.length >= pageSize
          : tickets.length < result.totalCount!;
      _pages[status] = (_pages[status] ?? 1) + 1;

      if (status == 0) {
        for (final ticket in result.items) {
          await _saveQrCodeLocally(ticket);
        }
      }
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loadingStatuses.remove(status);
      notifyListeners();
    }
  }

  List<TicketResponse> _ticketsForStatus(int status) {
    switch (status) {
      case 0:
        return activeTickets;
      case 1:
        return usedTickets;
      case 2:
        return cancelledTickets;
      default:
        return activeTickets;
    }
  }

  Future<TicketResponse?> getTicketById(int id) async {
    try {
      return await _baseProvider.get<TicketResponse>(
        '${ApiConstants.tickets}/$id',
        fromJson: (json) => TicketResponse.fromJson(json),
      );
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<void> _saveQrCodeLocally(TicketResponse ticket) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qr_ticket_${ticket.id}', ticket.qrCodePayload);
  }

  Future<String?> getLocalQrCode(int ticketId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('qr_ticket_$ticketId');
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
