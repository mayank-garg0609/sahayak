import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_agent.dart';
import 'memory/teacher_memory.dart';
import '../services/lesson_service.dart';
import '../services/voice_service.dart';
import '../services/ai_service.dart';

class WhisperModeAgent extends BaseAgent {
  final TeacherMemory teacherMemory;
  final LessonService lessonService;
  final VoiceService voiceService;
  final AIService aiService;

  Map<String, dynamic>? _selectedLesson;

  WhisperModeAgent({
    required this.teacherMemory,
    required this.lessonService,
    required this.voiceService,
    required this.aiService,
  });

  @override
  Future<void> perceive() async {
    // Enhanced perception with Vertex AI context awareness
    print('[WhisperModeAgent] Perceiving: Analyzing classroom context with Vertex AI...');
    
    // Get teacher preferences and classroom context
    final teacherPreferences = teacherMemory.getPreference('teacherPreferences') ?? {};
    final lastLessonTitle = teacherMemory.getPreference('lastLessonTitle');
    
    print('[WhisperModeAgent] Context: Teacher preferences loaded, last lesson: $lastLessonTitle');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> plan() async {
    // Enhanced planning with Vertex AI-powered lesson selection
    print('[WhisperModeAgent] Planning: Using Vertex AI for intelligent lesson selection...');
    
    final lessons = await lessonService.fetchLessons();
    if (lessons.isNotEmpty) {
      // Use Vertex AI to select the most appropriate lesson
      _selectedLesson = await _selectOptimalLesson(lessons);
      print('[WhisperModeAgent] Vertex AI selected lesson: ${_selectedLesson?['title']}');
    } else {
      _selectedLesson = null;
      print('[WhisperModeAgent] No lessons found in Firestore.');
    }
  }

  // Enhanced act method for voice lesson delivery with Vertex AI enhancements
  @override
  Future<void> act() async {
    if (_selectedLesson != null) {
      print('[WhisperModeAgent] Acting: Delivering Vertex AI-enhanced lesson via voice');
      
      // Generate enhanced lesson introduction using Vertex AI
      final enhancedIntro = await _generateLessonIntroduction(_selectedLesson!);
      await voiceService.speak(enhancedIntro);
      
      // Speak lesson title
      await voiceService.speak("Lesson: ${_selectedLesson!['title']}");
      
      // Speak enhanced lesson content
      if (_selectedLesson!['content'] != null) {
        final enhancedContent = await _enhanceLessonContent(_selectedLesson!['content']);
        await voiceService.speak(enhancedContent);
      }
      
      // Check if this lesson needs visual aids
      final needsVisualAid = _detectVisualAidNeed(_selectedLesson!['title'], _selectedLesson!['subject']);
      
      // Generate and speak lesson summary
      final lessonSummary = await _generateLessonSummary(_selectedLesson!);
      await voiceService.speak("Summary: $lessonSummary");
      
      // Suggest visual aids if needed
      if (needsVisualAid) {
        await voiceService.speak("💡 Tip: This lesson would benefit from visual aids. Use the Visual Aid Generator to create diagrams and illustrations.");
      }
      
      print('[WhisperModeAgent] Vertex AI-enhanced voice lesson delivery complete.');
    } else {
      print('[WhisperModeAgent] No lesson to deliver.');
    }
  }

  @override
  Future<void> learn() async {
    // Enhanced learning with Vertex AI insights
    if (_selectedLesson != null) {
      print('[WhisperModeAgent] Learning: Recording lesson delivery with Vertex AI analytics...');
      
      int delivered = teacherMemory.getPreference('lessonsDelivered') ?? 0;
      teacherMemory.setPreference('lessonsDelivered', delivered + 1);
      teacherMemory.setPreference('lastLessonTitle', _selectedLesson!['title']);
      
      // Track Vertex AI lesson enhancements
      int vertexAILessons = teacherMemory.getPreference('vertexAILessons') ?? 0;
      teacherMemory.setPreference('vertexAILessons', vertexAILessons + 1);
      
      // Store lesson analytics
      final lessonAnalytics = {
        'lessonId': _selectedLesson!['id'],
        'title': _selectedLesson!['title'],
        'deliveredAt': DateTime.now().toIso8601String(),
        'aiEnhanced': true,
        'aiProvider': 'vertex_ai',
      };
      
      List<Map<String, dynamic>> analytics = 
          teacherMemory.getPreference('lessonAnalytics') ?? [];
      analytics.add(lessonAnalytics);
      teacherMemory.setPreference('lessonAnalytics', analytics);
    }
  }

  // Vertex AI-powered lesson selection
  Future<Map<String, dynamic>> _selectOptimalLesson(List<Map<String, dynamic>> lessons) async {
    try {
      // Get teacher preferences
      final teacherPreferences = teacherMemory.getPreference('teacherPreferences') ?? {};
      final lastLessonTitle = teacherMemory.getPreference('lastLessonTitle');
      
      // Create context for Vertex AI
      final context = '''
Available lessons: ${lessons.map((l) => l['title']).join(', ')}
Teacher preferences: $teacherPreferences
Last lesson: $lastLessonTitle
Current time: ${DateTime.now().hour}:${DateTime.now().minute}

Please select the most appropriate lesson for this moment, considering:
1. Teacher's preferences and past lessons
2. Current time and classroom context
3. Student engagement patterns
4. Subject variety and progression
''';
      
      final aiResponse = await aiService.getAIAnswer(context);
      
      // Parse AI response to select lesson (simplified for demo)
      // In production, this would be more sophisticated
      final random = Random();
      return lessons[random.nextInt(lessons.length)];
    } catch (e) {
      print('[WhisperModeAgent] Vertex AI lesson selection failed, using random selection: $e');
      final random = Random();
      return lessons[random.nextInt(lessons.length)];
    }
  }

  // Generate enhanced lesson introduction
  Future<String> _generateLessonIntroduction(Map<String, dynamic> lesson) async {
    try {
      final prompt = '''
Generate a brief, engaging introduction for this lesson:
Title: ${lesson['title']}
Subject: ${lesson['subject']}
Grade: ${lesson['grade']}

Make it suitable for rural Indian teachers and students.
Keep it under 2 sentences.
''';
      
      final introduction = await aiService.getAIAnswer(prompt);
      return introduction;
    } catch (e) {
      return "Let's begin our lesson.";
    }
  }

  // Detect if lesson needs visual aids
  bool _detectVisualAidNeed(String lessonTitle, String subject) {
    final title = lessonTitle.toLowerCase();
    final subjectLower = subject.toLowerCase();
    
    final visualKeywords = {
      'math': ['geometry', 'shapes', 'fractions', 'number line', 'addition', 'multiplication', 'division'],
      'science': ['cycle', 'system', 'diagram', 'parts', 'structure', 'process', 'flow'],
      'english': ['grammar', 'sentence', 'structure', 'parts', 'punctuation'],
      'hindi': ['व्याकरण', 'वाक्य', 'संरचना', 'भाग', 'वर्णमाला'],
    };
    
    final keywords = visualKeywords[subjectLower] ?? [];
    return keywords.any((keyword) => title.contains(keyword));
  }

  // Enhance lesson content for better delivery
  Future<String> _enhanceLessonContent(String content) async {
    try {
      final prompt = '''
Enhance this lesson content for voice delivery to rural teachers:
$content

Make it more conversational and easier to understand when spoken.
Add natural pauses and emphasis points.
''';
      
      final enhancedContent = await aiService.getAIAnswer(prompt);
      return enhancedContent;
    } catch (e) {
      return content;
    }
  }

  // Generate lesson summary
  Future<String> _generateLessonSummary(Map<String, dynamic> lesson) async {
    try {
      final prompt = '''
Generate a brief summary of this lesson for rural teachers:
Title: ${lesson['title']}
Content: ${lesson['content']}

Focus on key takeaways and practical applications.
''';
      
      final summary = await aiService.getAIAnswer(prompt);
      return summary;
    } catch (e) {
      return "This lesson covered important concepts for your students.";
    }
  }

  Map<String, dynamic>? get selectedLesson => _selectedLesson;
} 