import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  // Stream controllers for real-time voice feedback
  final StreamController<String> _speechResultController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningStateController = StreamController<bool>.broadcast();
  final StreamController<bool> _speakingStateController = StreamController<bool>.broadcast();

  Stream<String> get speechResultStream => _speechResultController.stream;
  Stream<bool> get listeningStateStream => _listeningStateController.stream;
  Stream<bool> get speakingStateStream => _speakingStateController.stream;

  Future<void> initialize() async {
    // Request microphone permission
    await Permission.microphone.request();
    
    // Initialize speech recognition
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );

    // Initialize TTS
    await _flutterTts.setLanguage("hi-IN"); // Hindi for rural India
    await _flutterTts.setSpeechRate(0.5); // Slower for clarity
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set up TTS callbacks
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _speakingStateController.add(true);
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _speakingStateController.add(false);
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      _speakingStateController.add(false);
      print('TTS Error: $msg');
    });
  }

  Future<void> startListening() async {
    if (!_speechEnabled) {
      print('Speech recognition not available');
      return;
    }

    if (_isListening) return;

    _isListening = true;
    _listeningStateController.add(true);

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          _speechResultController.add(result.recognizedWords);
          _isListening = false;
          _listeningStateController.add(false);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
      localeId: "hi_IN", // Hindi locale
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    _listeningStateController.add(false);
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    _speakingStateController.add(false);
  }

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get speechEnabled => _speechEnabled;

  void dispose() {
    _speechResultController.close();
    _listeningStateController.close();
    _speakingStateController.close();
  }
} 