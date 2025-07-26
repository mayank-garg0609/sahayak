import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class VertexAIService {
  static const String _offlineQueueBox = 'vertex_ai_offline_queue';
  static const int _rateLimitPerMinute = 60;
  
  // Updated project ID for sahayak-mvp-2025
  static const String _projectId = 'sahayak-mvp-2025';
  static const String _location = 'us-central1';
  
  http.Client? _authenticatedClient;
  bool _isInitialized = false;
  int _requestCount = 0;
  DateTime _windowStart = DateTime.now();

  VertexAIService() {
    _initHive();
  }

  // Add missing initialize() method
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive for offline queuing
      await _initHive();
      
      // Initialize Google Cloud authentication
      await _initializeAuthentication();
      
      _isInitialized = true;
      print('[VertexAIService] Initialized successfully with Google Cloud authentication');
    } catch (e) {
      print('[VertexAIService] Initialization failed: $e');
      // Continue without authentication for offline mode
    }
  }

  Future<void> _initHive() async {
    if (!Hive.isBoxOpen(_offlineQueueBox)) {
      Directory dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
      await Hive.openBox(_offlineQueueBox);
    }
  }

  Future<void> _initializeAuthentication() async {
    if (_authenticatedClient != null) return;

    try {
      // Read service account JSON from assets
      final String serviceAccountJson = await rootBundle.loadString('assets/google_service_account.json');
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJson));
      
      // Create authenticated client with correct scopes
      _authenticatedClient = await clientViaServiceAccount(
        serviceAccountCredentials,
        ['https://www.googleapis.com/auth/cloud-platform']
      );
      
      print('[VertexAI] Authentication successful');
    } catch (e) {
      print('[VertexAI] Authentication failed: $e');
      // Fallback to basic HTTP client for development
      _authenticatedClient = http.Client();
    }
  }

  Future<String> getAIAnswer(String question) async {
    // Rate limiting
    if (!_canMakeRequest()) {
      await _queueQuestion(question);
      return "AI is busy. Your question has been queued and will be answered soon.";
    }

    await _initializeAuthentication();

    // Enhanced rural education context prompt
    final prompt = '''
You are Sahayak, an advanced AI assistant specifically designed for rural teachers in India. 
Provide clear, practical, and culturally relevant answers for multi-grade classrooms with limited resources.
Consider the following context:
- Rural Indian classroom environment
- Limited technological resources
- Mixed Hindi/English language usage
- Multi-grade teaching scenarios
- Local cultural contexts

Question: $question

Provide a helpful, actionable response in simple language that a rural teacher can immediately implement.
''';

    try {
      final url = 'https://generativelanguage.googleapis.com/v1//$_projectId/locations/$_location/publishers/google/models/gemini-1.5-pro:generateContent';
      
      final response = await _authenticatedClient!.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = _parseVertexAIResponse(data);
        _incrementRequestCount();
        return answer;
      } else {
        print('[VertexAI] API Error: ${response.statusCode} - ${response.body}');
        await _queueQuestion(question);
        return "AI service error: ${response.statusCode}. Your question has been queued.";
      }
    } catch (e) {
      print('[VertexAI] Exception: $e');
      await _queueQuestion(question);
      return "AI service unavailable. Your question has been queued.";
    }
  }

  String _parseVertexAIResponse(dynamic data) {
    try {
      final candidates = data['candidates'];
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
          return content['parts'][0]['text'] ?? "No answer found.";
        }
      }
      return "No answer found.";
    } catch (e) {
      print('[VertexAI] Response parsing error: $e');
      return "Failed to parse AI response.";
    }
  }

  bool _canMakeRequest() {
    final now = DateTime.now();
    if (now.difference(_windowStart).inMinutes >= 1) {
      _windowStart = now;
      _requestCount = 0;
    }
    return _requestCount < _rateLimitPerMinute;
  }

  void _incrementRequestCount() {
    _requestCount += 1;
  }

  Future<void> _queueQuestion(String question) async {
    final box = await Hive.openBox(_offlineQueueBox);
    await box.add({
      'question': question,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> processOfflineQueue() async {
    final box = await Hive.openBox(_offlineQueueBox);
    final List queued = box.values.toList();
    for (var item in queued) {
      final question = item['question'];
      await getAIAnswer(question);
    }
    await box.clear();
  }

  // Add missing getServiceStatus() method
  Map<String, dynamic> getServiceStatus() {
    return {
      'isInitialized': _isInitialized,
      'isAuthenticated': _authenticatedClient != null,
      'requestCount': _requestCount,
      'windowStart': _windowStart.toIso8601String(),
      'projectId': _projectId,
      'location': _location,
    };
  }

  void dispose() {
    _authenticatedClient?.close();
  }
}
