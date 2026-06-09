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
  bool isLoading = false;
  String? error;

  TicketProvider(this._baseProvider);

  Future<void> loadTickets() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final activeResult = await _baseProvider.get<PageResult<TicketResponse>>(
        ApiConstants.tickets,
        queryParameters: {'page': 1, 'pageSize': 100, 'status': 0},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => TicketResponse.fromJson(item),
        ),
      );
      activeTickets = activeResult.items;

      final usedResult = await _baseProvider.get<PageResult<TicketResponse>>(
        ApiConstants.tickets,
        queryParameters: {'page': 1, 'pageSize': 100, 'status': 1},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => TicketResponse.fromJson(item),
        ),
      );
      usedTickets = usedResult.items;

      final cancelledResult = await _baseProvider.get<PageResult<TicketResponse>>(
        ApiConstants.tickets,
        queryParameters: {'page': 1, 'pageSize': 100, 'status': 2},
        fromJson: (json) => PageResult.fromJson(
          json,
          (item) => TicketResponse.fromJson(item),
        ),
      );
      cancelledTickets = cancelledResult.items;

      for (final ticket in activeTickets) {
        await _saveQrCodeLocally(ticket);
      }
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
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
