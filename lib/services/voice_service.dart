import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends ChangeNotifier {
  late stt.SpeechToText _speech;
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidence = 0.0;

  // Voice commands mapping
  final Map<String, String> _commandMap = {
    'maju': 'forward',
    'mundur': 'backward',
    'kiri': 'left',
    'kanan': 'right',
    'berhenti': 'stop',
    'stop': 'stop',
    'forward': 'forward',
    'backward': 'backward',
    'left': 'left',
    'right': 'right',
  };

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidence => _confidence;
  List<String> get availableCommands => _commandMap.keys.toList();

  VoiceService() {
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (kDebugMode) {
          print('❌ Microphone permission denied');
        }
        return;
      }

      _speech = stt.SpeechToText();
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          if (kDebugMode) {
            print('🎤 Speech status: $status');
          }
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ Speech error: $error');
          }
          _isListening = false;
          notifyListeners();
        },
      );

      if (kDebugMode) {
        print('✅ Speech-to-text initialized: $_isAvailable');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Speech initialization error: $e');
      }
      _isAvailable = false;
      notifyListeners();
    }
  }

  void startListening({Function(String)? onCommand}) async {
    if (!_isAvailable) {
      if (kDebugMode) {
        print('⚠️ Speech recognition not available');
      }
      return;
    }

    if (_isListening) {
      stopListening();
      return;
    }

    try {
      _isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords.toLowerCase();
          _confidence = result.confidence;

          if (kDebugMode) {
            print('🎤 Heard: $_lastWords (confidence: $_confidence)');
          }

          // Check if any command matches
          String? matchedCommand = _findMatchingCommand(_lastWords);
          if (matchedCommand != null && _confidence > 0.5) {
            if (kDebugMode) {
              print('✅ Command recognized: $matchedCommand');
            }
            onCommand?.call(matchedCommand);
            stopListening(); // Stop after command recognized
          }

          notifyListeners();
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        localeId: 'id_ID', // Indonesian locale
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Speech recognition error: $e');
      }
      _isListening = false;
      notifyListeners();
    }
  }

  void stopListening() {
    if (_isListening) {
      try {
        _speech.stop();
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error stopping speech service: $e');
        }
      }
      _isListening = false;
      notifyListeners();
    }
  }

  String? _findMatchingCommand(String spokenText) {
    // Clean the spoken text
    String cleanText = spokenText.toLowerCase().trim();

    // Direct match
    if (_commandMap.containsKey(cleanText)) {
      return _commandMap[cleanText];
    }

    // Partial match - check if any command is contained in the spoken text
    for (String command in _commandMap.keys) {
      if (cleanText.contains(command)) {
        return _commandMap[command];
      }
    }

    return null;
  }

  // Get display name for command
  String getDisplayName(String command) {
    switch (command) {
      case 'forward':
        return 'Maju';
      case 'backward':
        return 'Mundur';
      case 'left':
        return 'Kiri';
      case 'right':
        return 'Kanan';
      case 'stop':
        return 'Berhenti';
      default:
        return command;
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
