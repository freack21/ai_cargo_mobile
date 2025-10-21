import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService extends ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;
  String _serverUrl = 'http://192.168.4.1:5000';
  Timer? _reconnectTimer;

  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;

  void setServerUrl(String url) {
    _serverUrl = url;
    notifyListeners();
  }

  void connect() {
    try {
      _socket?.dispose();

      _socket = IO.io(
          _serverUrl,
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .setReconnectionAttempts(5)
              .setReconnectionDelay(2000)
              .build());

      _socket!.onConnect((_) {
        print('🟢 Connected to robot server: $_serverUrl');
        _isConnected = true;
        _cancelReconnectTimer();
        notifyListeners();
      });

      _socket!.onDisconnect((_) {
        print('🔴 Disconnected from robot server');
        _isConnected = false;
        notifyListeners();
        _startReconnectTimer();
      });

      _socket!.onConnectError((error) {
        print('❌ Connection error: $error');
        _isConnected = false;
        notifyListeners();
        _startReconnectTimer();
      });

      _socket!.connect();
    } catch (e) {
      print('❌ Socket connection failed: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void disconnect() {
    _cancelReconnectTimer();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  void _startReconnectTimer() {
    _cancelReconnectTimer();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        print('🔄 Attempting to reconnect...');
        connect();
      } else {
        timer.cancel();
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Send joystick command
  void sendJoystickCommand(String command) {
    if (_socket != null && _isConnected) {
      _socket!.emit('joystick_command', {
        'command': command,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('📤 Sent joystick command: $command');
    } else {
      print('⚠️ Cannot send command - not connected');
    }
  }

  // Send voice command
  void sendVoiceCommand(String command) {
    if (_socket != null && _isConnected) {
      _socket!.emit('voice_command', {
        'command': command,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('📤 Sent voice command: $command');
    } else {
      print('⚠️ Cannot send command - not connected');
    }
  }

  // Send command sequence
  void sendCommandSequence(List<Map<String, dynamic>> commands) {
    if (_socket != null && _isConnected) {
      _socket!.emit('run_commands', {
        'command': 'run_commands',
        'data': commands,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('📤 Sent command sequence: ${commands.length} commands');
    } else {
      print('⚠️ Cannot send commands - not connected');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
