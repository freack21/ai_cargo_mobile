import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/socket_service.dart';
import 'joystick_control_page.dart';
import 'voice_control_page.dart';
import 'command_sequence_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF4FC3F7), // Light Blue
              const Color(0xFF81C784), // Light Green
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with connection status
              _buildHeader(context),
              
              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App title
                      _buildTitle(),
                      
                      const SizedBox(height: 40),
                      
                      // Robot illustration
                      _buildRobotIllustration(),
                      
                      const SizedBox(height: 40),
                      
                      // Menu buttons
                      _buildMenuButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<SocketService>(
      builder: (context, socketService, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                socketService.isConnected ? Icons.wifi : Icons.wifi_off,
                color: socketService.isConnected ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                socketService.isConnected ? 'Terhubung' : 'Terputus',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showConnectionDialog(context),
                icon: const Icon(Icons.settings, color: Colors.white),
                tooltip: 'Pengaturan Koneksi',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          '🤖',
          style: const TextStyle(fontSize: 60),
        ),
        const SizedBox(height: 16),
        Text(
          'Robot Edukasi',
          style: GoogleFonts.nunito(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        Text(
          'Kontrol Robot Pintar',
          style: GoogleFonts.nunito(
            fontSize: 18,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRobotIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
      ),
      child: const Icon(
        Icons.smart_toy,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMenuButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMenuButton(
                context,
                '🕹️',
                'Kontrol\nJoystick',
                const Color(0xFFFFEB3B), // Yellow
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoystickControlPage()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuButton(
                context,
                '🎤',
                'Kontrol\nSuara',
                const Color(0xFFFF8A80), // Light Red
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VoiceControlPage()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMenuButton(
                context,
                '📋',
                'Susun\nPerintah',
                const Color(0xFF81C784), // Light Green
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CommandSequencePage()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMenuButton(
                context,
                '🚪',
                'Keluar',
                const Color(0xFFFFAB91), // Light Orange
                () => _showExitDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String emoji,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionDialog(BuildContext context) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    final controller = TextEditingController(text: socketService.serverUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Pengaturan Koneksi',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'URL Server Robot',
                hintText: 'http://192.168.4.1:3210',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              socketService.setServerUrl(controller.text.trim());
              socketService.connect();
              Navigator.pop(context);
            },
            child: const Text('Hubungkan'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Keluar Aplikasi',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah kamu yakin ingin keluar?',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }
}
