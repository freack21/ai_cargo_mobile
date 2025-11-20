import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../services/socket_service.dart';
import '../services/voice_service.dart';

class VoiceControlPage extends StatefulWidget {
  const VoiceControlPage({super.key});

  @override
  State<VoiceControlPage> createState() => _VoiceControlPageState();
}

class _VoiceControlPageState extends State<VoiceControlPage>
    with TickerProviderStateMixin {
  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;
  String _lastCommand = '';

  @override
  void initState() {
    super.initState();
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _micAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _micAnimationController,
      curve: Curves.easeInOut,
    ));

    // Auto connect when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      if (!socketService.isConnected) {
        socketService.connect();
      }
    });
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🎤 Kontrol Suara',
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
              const Color(0xFFFF8A80).withOpacity(0.1),
              const Color(0xFF4FC3F7).withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Connection status
              _buildConnectionStatus(),

              // Voice status and mic
              Expanded(
                child: _buildVoiceArea(),
              ),

              // Available commands
              _buildAvailableCommands(),
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
                child: Text(
                  socketService.isConnected
                      ? 'Robot Siap Menerima Perintah'
                      : 'Robot Tidak Terhubung',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        socketService.isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceArea() {
    return Consumer2<VoiceService, SocketService>(
      builder: (context, voiceService, socketService, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Voice status text
            _buildVoiceStatus(voiceService),

            const SizedBox(height: 20),

            // Real-time speech display (when recording)
            if (voiceService.isListening && voiceService.lastWords.isNotEmpty)
              _buildRealTimeSpeech(voiceService),

            const SizedBox(height: 20),

            // Animated microphone button
            _buildMicButton(voiceService, socketService),

            const SizedBox(height: 40),

            // Last recognized command
            _buildLastCommand(voiceService),
          ],
        );
      },
    );
  }

  Widget _buildVoiceStatus(VoiceService voiceService) {
    if (!voiceService.isAvailable) {
      return Text(
        'Mikrofon tidak tersedia',
        style: GoogleFonts.nunito(
          fontSize: 18,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (voiceService.isListening) {
      return Column(
        children: [
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                '🎤 Merekam...',
                textStyle: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                speed: const Duration(milliseconds: 100),
              ),
            ],
            repeatForever: true,
          ),
          const SizedBox(height: 8),
          Text(
            'Lepas untuk mengirim perintah',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          '🎤 Tahan untuk Merekam',
          style: GoogleFonts.nunito(
            fontSize: 20,
            color: const Color(0xFF4FC3F7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Seperti voice note WhatsApp',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMicButton(
      VoiceService voiceService, SocketService socketService) {
    if (voiceService.isListening) {
      _micAnimationController.repeat(reverse: true);
    } else {
      _micAnimationController.stop();
      _micAnimationController.reset();
    }

    return AnimatedBuilder(
      animation: _micAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: voiceService.isListening ? _micAnimation.value : 1.0,
          child: GestureDetector(
            // Hold to record like WhatsApp voice note
            onTapDown: (_) {
              HapticFeedback.mediumImpact();
              voiceService.startRecording();
            },
            onTapUp: (_) {
              HapticFeedback.heavyImpact();
              voiceService.stopListening();
              // Process the recording after user releases
              voiceService.processRecording(
                onCommand: (command) {
                  setState(() {
                    _lastCommand = command;
                  });
                  socketService.sendVoiceCommand(command);
                  HapticFeedback.heavyImpact();
                },
              );
            },
            onTapCancel: () {
              // If user drags away, cancel recording
              voiceService.stopListening();
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: voiceService.isListening
                    ? Colors.red
                    : const Color(0xFF4FC3F7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (voiceService.isListening
                            ? Colors.red
                            : const Color(0xFF4FC3F7))
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: voiceService.isListening ? 15 : 5,
                  ),
                ],
              ),
              child: Icon(
                voiceService.isListening ? Icons.mic : Icons.mic_none,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealTimeSpeech(VoiceService voiceService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Yang Didengar:',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.red[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"${voiceService.lastWords}"',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.red[800],
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLastCommand(VoiceService voiceService) {
    if (_lastCommand.isEmpty && voiceService.lastWords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          if (_lastCommand.isNotEmpty) ...[
            Text(
              'Perintah Terakhir:',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              voiceService.getDisplayName(_lastCommand),
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
//          if (voiceService.lastWords.isNotEmpty) ...[
//            const SizedBox(height: 8),
//            Text(
//              'Yang Didengar: "${voiceService.lastWords}"',
//              style: GoogleFonts.nunito(
//                fontSize: 12,
//                color: Colors.grey[500],
//                fontStyle: FontStyle.italic,
//              ),
//            ),
//          ],
        ],
      ),
    );
  }

  Widget _buildAvailableCommands() {
    return Consumer<VoiceService>(
      builder: (context, voiceService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📝 Perintah yang Tersedia',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCommandChip('maju', '⬆️', Colors.green),
                  _buildCommandChip('mundur', '⬇️', Colors.orange),
                  _buildCommandChip('kiri', '⬅️', Colors.blue),
                  _buildCommandChip('kanan', '➡️', Colors.purple),
                  _buildCommandChip('berhenti', '⏹️', Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandChip(String command, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '"$command"',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
