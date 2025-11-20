import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/socket_service.dart';
import 'joystick_control_page.dart';
import 'voice_control_page.dart';
import 'command_sequence_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _autoStopEnabled = false;

  @override
  void initState() {
    super.initState();

    // Auto connect when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      if (!socketService.isConnected) {
        socketService.connect();
      }

      // Listen for ping events to refresh auto_stop status
      socketService.socket?.on('ping', (data) {
        if (data != null && data is Map && data.containsKey('auto_stop')) {
          setState(() {
            _autoStopEnabled = data['auto_stop'] ?? false;
          });
        }
      });
    });
  }

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

              // Main content - Scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // App title
                      _buildTitle(),

                      // const SizedBox(height: 30),

                      // // Robot illustration
                      // _buildRobotIllustration(),

                      const SizedBox(height: 20),

                      // Auto Stop Control
                      _buildAutoStopControl(context),

                      const SizedBox(height: 20),

                      // Menu buttons
                      _buildMenuButtons(context),

                      // Bottom padding for safe scrolling
                      const SizedBox(height: 20),
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
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 16),
        Text(
          'Robot Edukasi',
          style: GoogleFonts.nunito(
            fontSize: 28,
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
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRobotIllustration() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
      ),
      child: const Icon(
        Icons.smart_toy,
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAutoStopControl(BuildContext context) {
    return Consumer<SocketService>(
      builder: (context, socketService, child) {
        return Container(
          // margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: _autoStopEnabled
                  ? Colors.green
                  : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Title with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stop_circle,
                    color: _autoStopEnabled ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Auto Stop',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _autoStopEnabled
                          ? Colors.green[700]
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Description
              Text(
                _autoStopEnabled
                    ? 'Robot akan berhenti otomatis jika ada halangan'
                    : 'Robot tidak akan berhenti otomatis',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Toggle Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _autoStopEnabled ? 'Aktif' : 'Nonaktif',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _autoStopEnabled
                          ? Colors.green[700]
                          : Colors.grey[700],
                    ),
                  ),
                  Transform.scale(
                    scale: 1.2,
                    child: Switch(
                      value: _autoStopEnabled,
                      activeColor: Colors.green,
                      activeTrackColor: Colors.green.withOpacity(0.3),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.withOpacity(0.3),
                      onChanged: socketService.isConnected
                          ? (value) {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _autoStopEnabled = value;
                              });
                              socketService.sendAutoStop(value);

                              // Show feedback
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        value
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        value
                                            ? '🛡️ Auto Stop diaktifkan!'
                                            : '⚠️ Auto Stop dimatikan!',
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor:
                                      value ? Colors.green : Colors.orange,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                ],
              ),

              // Connection status indicator
              if (!socketService.isConnected) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Perlu koneksi robot',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
                  MaterialPageRoute(
                      builder: (_) => const JoystickControlPage()),
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
                  MaterialPageRoute(
                      builder: (_) => const CommandSequencePage()),
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
