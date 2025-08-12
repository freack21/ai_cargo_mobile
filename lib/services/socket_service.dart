import 'package:ai_cargo_mobile/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect(Function(bool) onConnectionChanged) {
    socket = IO.io(wsUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to server!');
      onConnectionChanged(true);
    });

    socket.onDisconnect((_) {
      print('Disconnected from server');
      onConnectionChanged(false);
    });
  }

  void sendCommand(String perintah) {
    socket.emit('kirim-perintah', {'perintah': perintah, 'robot': "aikargo"});
  }
}
