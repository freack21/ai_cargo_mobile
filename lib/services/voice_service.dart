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
    'maju': 'maju',
    'mundur': 'mundur',
    'kiri': 'kiri',
    'kanan': 'kanan',
    'berhenti': 'berhenti',
    'stop': 'berhenti',
    'maju': 'maju',
    'mundur': 'mundur',
    'kiri': 'kiri',
    'kanan': 'kanan',
  };

  final Map<String, List<String>> _aliasMap = {
    'maju': [
      'mind you',
      'maggio',
      'module',
      'mad you',
      'macho',
      'majoo',
      'magu',
      'might you',
      'my you',
      'madju',
      'ma joo',
      'mudge you',
      'march you',
      'mug you',
      'mudge',
      'mood you',
      'madu',
      'match you',
      'much you',
      'mojo',
      'menu',
      'maggioo',
      'mago',
      'major',
      'margin',
      'magic',
      'my jaw',
      'my joy',
      'majuu',
      'mad shoe',
      'mood zoo',
    ],
    'mundur': [
      'moon door',
      'munder',
      'mundo',
      'mount door',
      'moon do',
      'wonder',
      'mounder',
      'mooder',
      'munderu',
      'moon der',
      'mon dur',
      'moon tour',
      'moondoor',
      'moondor',
      'mundu',
      'mundoor',
      'mound door',
      'moonder',
      'moonderr',
      'moon deer',
      'mon door',
      'moon dure',
      'mundure',
      'mourn door',
      'mourned or',
      'mon dur',
      'monday',
      'mourned her',
    ],
    'kiri': [
      'carry',
      'curry',
      'kerry',
      'carey',
      'keary',
      'key re',
      'killy',
      'kiddy',
      'kitty',
      'siri',
      'kiri',
      'kirie',
      'kirry',
      'kili',
      'kirri',
      'kiddy',
      'kee ree',
      'key rye',
      'kira',
      'query',
      'curie',
      'carry on',
      'caring',
      'killing',
      'keely',
      'cherry',
      'gary',
      'giri',
      'greedy',
      'kiddy',
      'carie',
      'kirli',
      'cleary',
      'clary',
      'kiriee',
      'keerie',
    ],
    'kanan': [
      'canon',
      'cannon',
      'kanon',
      'canaan',
      'kannan',
      'kanan',
      'kanand',
      'can on',
      'can and',
      'kananah',
      'kan un',
      'canan',
      'cannonball',
      'kanone',
      'can none',
      'can end',
      'canan',
      'can then',
      'kan ant',
      'canan',
      'kan and',
      'canonball',
      'cana',
      'kanun',
      'kenan',
      'canine',
      'canon',
      'can in',
      'karen',
      'caren',
      'cannonball',
    ],
    'berhenti': [
      'stop',
      'stopped',
      'burgundy',
      'burn tea',
      'burn t',
      'beranti',
      'berhenti',
      'burnty',
      'burned tea',
      'burnt t',
      'burn thee',
      'burntye',
      'burn tee',
      'bird tea',
      'birthday',
      'birdie',
      'bernie',
      'berti',
      'berty',
      'burndy',
      'burn the',
      'burned e',
      'burnin tea',
      'burn t.',
      'brandy',
      'burundi',
      'burenty',
      'brunty',
      'burn tea stop',
      'burn to',
      'burned',
      'burni',
      'burton',
      'burn tee',
      'burne t',
      'burhenti',
      'barenty',
    ],
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

  // Start recording (like WhatsApp voice note - hold to record)
  void startRecording() async {
    if (!_isAvailable) {
      if (kDebugMode) {
        print('⚠️ Speech recognition not available');
      }
      return;
    }

    if (_isListening) {
      return; // Already recording
    }

    try {
      _isListening = true;
      _lastWords = ''; // Reset previous words
      _confidence = 0.0;
      notifyListeners();

      if (kDebugMode) {
        print('🎤 Started recording...');
      }

      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords.toLowerCase();
          _confidence = result.confidence;

          if (kDebugMode) {
            print('🎤 Partial result: $_lastWords (confidence: $_confidence)');
          }

          notifyListeners();
        },
        listenFor: const Duration(seconds: 30), // Max 30 seconds like WhatsApp
        pauseFor: const Duration(seconds: 1),
        partialResults: true,
        localeId: 'id_ID', // Indonesian locale
        cancelOnError: false,
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

  // Process the recorded audio when user releases the button
  void processRecording({Function(String)? onCommand}) {
    if (kDebugMode) {
      print('🎤 Processing recording: $_lastWords (confidence: $_confidence)');
    }

    if (_lastWords.isNotEmpty) {
      // Check if any command matches
      String? matchedCommand = _findMatchingCommand(_lastWords);
      if (matchedCommand != null && _confidence > 0.3) {
        if (kDebugMode) {
          print('✅ Command recognized: $matchedCommand');
        }
        onCommand?.call(matchedCommand);
      } else {
        if (kDebugMode) {
          print('❌ No command recognized from: $_lastWords');
        }
      }
    } else {
      if (kDebugMode) {
        print('❌ No speech detected');
      }
    }
  }

  // Legacy method for backward compatibility
  void startListening({Function(String)? onCommand}) async {
    startRecording();
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

    // Cek alias list
    for (final entry in _aliasMap.entries) {
      final command = entry.key;
      final aliases = entry.value;

      // Cek apakah spokenText sama persis dengan alias
      if (aliases.contains(cleanText)) {
        return command;
      }

      // Cek kalau spokenText mengandung alias (partial match)
      for (String alias in aliases) {
        if (cleanText.contains(alias)) {
          return command;
        }
      }
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
      case 'maju':
        return 'Maju';
      case 'mundur':
        return 'Mundur';
      case 'kiri':
        return 'Kiri';
      case 'kanan':
        return 'Kanan';
      case 'berhenti':
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
