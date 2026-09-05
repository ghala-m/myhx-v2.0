import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Voice dictation for history taking (English + Arabic).
class VoiceService with ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  double _level = 0;

  bool get isAvailable => _available;
  bool get isListening => _listening;
  String get transcript => _transcript;
  double get soundLevel => _level;

  Future<bool> init() async {
    try {
      _available = await _speech.initialize(
        onStatus: (status) {
          final listening = status == 'listening';
          if (listening != _listening) {
            _listening = listening;
            notifyListeners();
          }
        },
        onError: (_) {
          _listening = false;
          notifyListeners();
        },
      );
    } catch (_) {
      _available = false;
    }
    notifyListeners();
    return _available;
  }

  /// Starts dictation. [localeCode] should be 'ar' or 'en'.
  Future<void> start({
    String localeCode = 'en',
    required void Function(String text) onResult,
  }) async {
    if (!_available && !await init()) return;

    _transcript = '';
    await _speech.listen(
      localeId: localeCode == 'ar' ? 'ar_SA' : 'en_US',
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
      onSoundLevelChange: (level) {
        _level = level;
        notifyListeners();
      },
      onResult: (result) {
        _transcript = result.recognizedWords;
        notifyListeners();
        onResult(_transcript);
      },
    );
    _listening = true;
    notifyListeners();
  }

  Future<void> stop() async {
    await _speech.stop();
    _listening = false;
    _level = 0;
    notifyListeners();
  }

  Future<void> cancel() async {
    await _speech.cancel();
    _listening = false;
    _transcript = '';
    _level = 0;
    notifyListeners();
  }
}
