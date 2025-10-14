
import 'package:ai_cargo_mobile/services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class ManualControlPage extends StatefulWidget {
  const ManualControlPage({super.key});

  @override
  State<ManualControlPage> createState() => _ManualControlPageState();
}

class _ManualControlPageState extends State<ManualControlPage> {
  final SocketService socketService = SocketService();
  String myCommand = "";
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    socketService.connect((status) {
      setState(() {
        isOnline = status;
      });
    });
  }

  void handleJoystickMove(details) {
    String command = 'berhenti';

    if (details.y < -0.25 && details.x < -0.25) {
      command = 'kiri';
    } else if (details.y < -0.25 && details.x > 0.25) {
      command = 'kanan';
    } else if (details.y > 0.25 && details.x < -0.25) {
      command = 'mundur_kiri';
    } else if (details.y > 0.25 && details.x > 0.25) {
      command = 'mundur_kanan';
    } else if (details.y > 0.25) {
      command = 'mundur';
    } else if (details.y < -0.25) {
      command = 'maju';
    } else if (details.y > 0.25) {
      command = 'mundur';
    } else if (details.x < -0.25) {
      command = 'putar_kiri';
    } else if (details.x > 0.25) {
      command = 'putar_kanan';
    }

    if (command != myCommand) {
      myCommand = command;
      socketService.sendCommand(command);
    }
    // sleep(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Manual Control'),
            const Spacer(),
            Icon(
              isOnline ? Icons.circle : Icons.circle_outlined,
              color: isOnline ? Colors.green : Colors.red,
              size: 12,
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Joystick(
          listener: handleJoystickMove,
        ),
      ),
    );
  }
}
