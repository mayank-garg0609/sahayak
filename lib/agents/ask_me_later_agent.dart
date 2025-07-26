import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_agent.dart';
import 'memory/teacher_memory.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';

class AskMeLaterAgent extends BaseAgent {
  final TeacherMemory teacherMemory;
  final AIService aiService;
  final VoiceService voiceService;
  final FirebaseFirestore firestore;

  String? _lastQuestion;
  String? _lastAnswer;

  AskMeLaterAgent({
    required this.teacherMemory,
    required this.aiService,
    required this.voiceService,
    FirebaseFirestore? firestoreInstance,
  }) : firestore = firestoreInstance ?? FirebaseFirestore.instance;

  // Enhanced perceive method for voice input with Vertex AI context
  @override
  Future<void> perceive({String? question, bool isVoiceInput = false}) async {
    if (isVoiceInput) {
      // Start listening for voice input
      await voiceService.startListening();
      
      // Wait for speech result
      await for (String speechResult in voiceService.speechResultStream) {
        if (speechResult.isNotEmpty) {
          _lastQuestion = speechResult;
          print('[AskMeLaterAgent] Perceived voice question: $_lastQuestion');
          break;
        }
      }
    } else {
      _lastQuestion = question;
      print('[AskMeLaterAgent] Perceived text question: $_lastQuestion');
    }
  }

  // Enhanced plan method with Vertex AI integration
  @override
  Future<void> plan() async {
    if (_lastQuestion == null || _lastQuestion!.trim().isEmpty) return;
    
    // Add question to Firestore with enhanced metadata
    final questionDoc = await firestore.collection('questions').add({
      'question': _lastQuestion,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'source': 'vertex_ai_agent',
      'voiceInput': _lastQuestion!.contains('voice'),
    });
    print('[AskMeLaterAgent] Question added to Firestore queue with Vertex AI metadata.');

    // Call Vertex AI service for enhanced rural education responses
    final answer = await aiService.getAIAnswer(_lastQuestion!);
    _lastAnswer = answer;

    // Update Firestore with Vertex AI response
    await questionDoc.update({
      'answer': answer,
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
      'aiProvider': 'vertex_ai',
      'model': 'gemini-1.5-pro',
    });
    print('[AskMeLaterAgent] Vertex AI response stored in Firestore.');
  }

  // Enhanced act method for voice output with Vertex AI responses
  @override
  Future<void> act() async {
    if (_lastAnswer != null) {
      print('[AskMeLaterAgent] Acting: Speaking Vertex AI answer via TTS');
      
      // Enhance TTS with better pronunciation for rural education terms
      final enhancedAnswer = _enhanceForTTS(_lastAnswer!);
      await voiceService.speak(enhancedAnswer);
    }
  }

  // Enhanced learn method with Vertex AI insights
  @override
  Future<void> learn() async {
    if (_lastQuestion != null && _lastAnswer != null) {
      List<Map<String, String>> history =
          teacherMemory.getPreference('questionHistory') ?? [];
      
      // Enhanced history with Vertex AI metadata
      history.add({
        'q': _lastQuestion!, 
        'a': _lastAnswer!,
        'timestamp': DateTime.now().toIso8601String(),
        'aiProvider': 'vertex_ai',
        'model': 'gemini-1.5-pro',
      });
      
      teacherMemory.setPreference('questionHistory', history);
      
      // Track Vertex AI usage patterns
      int vertexAIUsage = teacherMemory.getPreference('vertexAIUsage') ?? 0;
      teacherMemory.setPreference('vertexAIUsage', vertexAIUsage + 1);
      
      print('[AskMeLaterAgent] Learning: Question/answer logged with Vertex AI insights.');
    }
  }

  // Helper method to enhance text for better TTS pronunciation
  String _enhanceForTTS(String text) {
    // Add pauses and emphasis for better rural education delivery
    return text
        .replaceAll('. ', '. ... ')
        .replaceAll('? ', '? ... ')
        .replaceAll('! ', '! ... ');
  }

  String? get lastQuestion => _lastQuestion;
  String? get lastAnswer => _lastAnswer;
} 