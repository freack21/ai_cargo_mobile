import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

import '../services/socket_service.dart';

class JoystickControlPage extends StatefulWidget {
  const JoystickControlPage({super.key});

  @override
  State<JoystickControlPage> createState() => _JoystickControlPageState();
}

class _JoystickControlPageState extends State<JoystickControlPage> {
  String _currentCommand = 'berhenti';
  bool _isControlling = false;

  @override
  void initState() {
    super.initState();
    // Auto connect when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      if (!socketService.isConnected) {
        socketService.connect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🕹️ Kontrol Joystick',
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4FC3F7).withOpacity(0.1),
              const Color(0xFFFFEB3B).withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Connection status
              _buildConnectionStatus(),
              
              // Current command display
              _buildCommandDisplay(),
              
              // Joystick area
              Expanded(
                child: _buildJoystickArea(),
              ),
              
              // Instructions
              _buildInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<SocketService>(
      builder: (context, socketService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: socketService.isConnected 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: socketService.isConnected ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                socketService.isConnected ? Icons.wifi : Icons.wifi_off,
                color: socketService.isConnected ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      socketService.isConnected ? 'Terhubung ke Robot' : 'Tidak Terhubung',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: socketService.isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      socketService.serverUrl,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (!socketService.isConnected)
                ElevatedButton(
                  onPressed: () => socketService.connect(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Hubungkan'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Perintah Saat Ini',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getCommandIcon(_currentCommand),
              const SizedBox(width: 12),
              Text(
                _getCommandText(_currentCommand),
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getCommandColor(_currentCommand),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoystickArea() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Joystick(
          mode: JoystickMode.all,
          listener: (details) {
            _handleJoystickMove(details);
          },
          base: JoystickBase(
            decoration: JoystickBaseDecoration(
              color: Colors.blue.withOpacity(0.3),
              drawOuterCircle: true,
            ),
            arrowsDecoration: JoystickArrowsDecoration(
              color: Colors.blue,
            ),
          ),
          stick: JoystickStick(
            decoration: JoystickStickDecoration(
              color: Colors.blue,
              shadowColor: Colors.blue.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '📖 Cara Menggunakan',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Gerakkan joystick untuk mengontrol robot\n'
            '• Atas: Robot maju\n'
            '• Bawah: Robot mundur\n'
            '• Kiri: Robot belok kiri\n'
            '• Kanan: Robot belok kanan\n'
            '• Tengah: Robot berhenti',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  void _handleJoystickMove(StickDragDetails details) {
    String newCommand = 'berhenti';
    
    // Determine command based on joystick position
    if (details.y > 0.5) {
      newCommand = 'mundur';
    } else if (details.y < -0.5) {
      newCommand = 'maju';
    } else if (details.x > 0.5) {
      newCommand = 'kanan';
    } else if (details.x < -0.5) {
      newCommand = 'kiri';
    }

    // Only send command if it changed
    if (newCommand != _currentCommand) {
      setState(() {
        _currentCommand = newCommand;
      });
      
      // Send command to robot
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.sendJoystickCommand(newCommand);
      
      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  Widget _getCommandIcon(String command) {
    IconData icon;
    switch (command) {
      case 'maju':
        icon = Icons.keyboard_arrow_up;
        break;
      case 'mundur':
        icon = Icons.keyboard_arrow_down;
        break;
      case 'kiri':
        icon = Icons.keyboard_arrow_left;
        break;
      case 'kanan':
        icon = Icons.keyboard_arrow_right;
        break;
      default:
        icon = Icons.stop;
    }
    
    return Icon(
      icon,
      size: 32,
      color: _getCommandColor(command),
    );
  }

  String _getCommandText(String command) {
    switch (command) {
      case 'maju':
        return 'MAJU';
      case 'mundur':
        return 'MUNDUR';
      case 'kiri':
        return 'KIRI';
      case 'kanan':
        return 'KANAN';
      default:
        return 'BERHENTI';
    }
  }

  Color _getCommandColor(String command) {
    switch (command) {
      case 'maju':
        return Colors.green;
      case 'mundur':
        return Colors.orange;
      case 'kiri':
        return Colors.blue;
      case 'kanan':
        return Colors.purple;
      default:
        return Colors.red;
    }
  }
}
