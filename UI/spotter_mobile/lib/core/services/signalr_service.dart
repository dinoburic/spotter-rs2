import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_constants.dart';

class SignalRService {
  HubConnection? _hubConnection;
  Function(Map<String, dynamic>)? onNotificationReceived;
  bool _isConnected = false;

  Future<void> startConnection(String token) async {
    if (_isConnected) return;

    final hubUrl = '${ApiConstants.baseUrl}/hubs/notifications';

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection!.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        onNotificationReceived?.call(data);
      }
    });

    _hubConnection!.onclose(({error}) {
      _isConnected = false;
    });

    _hubConnection!.onreconnected(({connectionId}) {
      _isConnected = true;
    });

    try {
      await _hubConnection!.start();
      _isConnected = true;
    } catch (_) {
      _isConnected = false;
    }
  }

  Future<void> stopConnection() async {
    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
      } catch (_) {}
    }
    _isConnected = false;
    _hubConnection = null;
  }

  bool get isConnected => _isConnected;
}
