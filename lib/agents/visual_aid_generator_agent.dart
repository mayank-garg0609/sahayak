import '../services/voice_service.dart';
import '../services/ai_service.dart';
import '../services/visual_aid_service.dart';
import '../agents/memory/teacher_memory.dart';
import '../agents/base_agent.dart';

class VisualAidGeneratorAgent extends BaseAgent {
  final VoiceService voiceService;
  final AIService aiService;
  final TeacherMemory teacherMemory;
  final VisualAidService visualAidService;
  
  String? _currentVisual;
  String? _currentExplanation;
  bool _isGenerating = false;
  
  // Visual aid templates for different subjects
  static const Map<String, List<String>> _visualTemplates = {
    'math': [
      'Number Line: 0 --- 1 --- 2 --- 3 --- 4 --- 5',
      'Fraction Circle: ⭕ 1/2 | 1/2',
      'Addition: 3 + 2 = 5 [●●●] + [●●] = [●●●●●]',
      'Multiplication: 3 × 4 = 12 [●●●][●●●][●●●][●●●]',
      'Place Value: 123 = 100 + 20 + 3',
    ],
    'science': [
      'Water Cycle: ☁️ → 🌧️ → 💧 → ☁️',
      'Plant Parts: 🌱 → 🌿 → 🌸 → 🍎',
      'Solar System: ☀️ → 🌍 → 🌙',
      'Food Chain: 🌱 → 🐛 → 🐦 → 🦊',
      'States of Matter: ❄️ → 💧 → 💨',
    ],
    'english': [
      'Parts of Speech: 📝 Noun | 📝 Verb | 📝 Adjective',
      'Sentence Structure: Subject + Verb + Object',
      'Punctuation: . , ! ? " " ( )',
      'Tenses: Past | Present | Future',
      'Synonyms: Happy = Joyful = Cheerful',
    ],
    'hindi': [
      'वर्णमाला: अ आ इ ई उ ऊ ए ऐ ओ औ',
      'संज्ञा: व्यक्ति | वस्तु | स्थान | भाव',
      'क्रिया: करना | जाना | आना | खाना',
      'विशेषण: बड़ा | छोटा | लाल | नीला',
      'लिंग: पुल्लिंग | स्त्रीलिंग | नपुंसकलिंग',
    ],
  };

  VisualAidGeneratorAgent({
    required this.voiceService,
    required this.aiService,
    required this.teacherMemory,
    required this.visualAidService,
  });

  @override
  Future<void> perceive() async {
    print('[VisualAidGeneratorAgent] Perceiving: Analyzing lesson content for visual opportunities...');
    
    // Get current lesson context from teacher memory
    final currentLesson = teacherMemory.getPreference('currentLesson');
    final subject = teacherMemory.getPreference('currentSubject') ?? 'math';
    final gradeLevel = teacherMemory.getPreference('gradeLevel') ?? 'primary';
    
    print('[VisualAidGeneratorAgent] Context: Subject=$subject, Grade=$gradeLevel, Lesson=$currentLesson');
    
    // Detect if current topic needs visual explanation
    final needsVisual = _detectVisualNeed(subject, currentLesson);
    
    if (needsVisual) {
      print('[VisualAidGeneratorAgent] Visual aid needed for: $currentLesson');
    }
  }

  @override
  Future<void> plan() async {
    print('[VisualAidGeneratorAgent] Planning: Generating intelligent visual content...');
    
    final subject = teacherMemory.getPreference('currentSubject') ?? 'math';
    final gradeLevel = teacherMemory.getPreference('gradeLevel') ?? 'primary';
    final currentLesson = teacherMemory.getPreference('currentLesson') ?? 'Basic Concepts';
    
    // Use Vertex AI to enhance visual generation
    final aiPrompt = '''
    Create a simple, clear visual representation for rural Indian students learning $subject at $gradeLevel level.
    Topic: $currentLesson
    
    Requirements:
    - Use simple symbols and text-based diagrams
    - Include Hindi and English labels where appropriate
    - Make it suitable for chalkboard or paper
    - Focus on clarity over complexity
    - Include a brief explanation in simple language
    
    Generate a visual diagram and explanation.
    ''';
    
    try {
      final aiResponse = await aiService.getAIAnswer(aiPrompt);
      _currentVisual = _extractVisualFromAI(aiResponse);
      _currentExplanation = _extractExplanationFromAI(aiResponse);
      
      print('[VisualAidGeneratorAgent] AI-enhanced visual generated successfully');
    } catch (e) {
      print('[VisualAidGeneratorAgent] AI generation failed, using template: $e');
      _currentVisual = _generateTemplateVisual(subject, currentLesson);
      _currentExplanation = _generateTemplateExplanation(subject, currentLesson);
    }
  }

  @override
  Future<void> act() async {
    print('[VisualAidGeneratorAgent] Acting: Displaying visual with synchronized voice explanation...');
    
    if (_currentVisual == null || _currentExplanation == null) {
      print('[VisualAidGeneratorAgent] No visual content to display');
      return;
    }
    
    _isGenerating = true;
    
    // Display the visual
    print('[VisualAidGeneratorAgent] Visual Content:');
    print(_currentVisual!);
    
    // Speak the explanation
    final enhancedExplanation = '''
    यहाँ आपके लिए एक स्पष्ट दृश्य सहायता है। 
    ${_currentExplanation!}
    इसे ध्यान से देखें और समझें।
    ''';
    
    await voiceService.speak(enhancedExplanation);
    
    // Store in teacher memory for future reference
    teacherMemory.setPreference('lastVisual', _currentVisual);
    teacherMemory.setPreference('lastVisualExplanation', _currentExplanation);
    teacherMemory.setPreference('visualGeneratedAt', DateTime.now().toIso8601String());
    
    // Save to Firestore for persistence
    try {
      final teacherId = teacherMemory.getPreference('teacherId') ?? 'default_teacher';
      final subject = teacherMemory.getPreference('currentSubject') ?? 'math';
      final gradeLevel = teacherMemory.getPreference('gradeLevel') ?? 'primary';
      
      await visualAidService.saveVisualAid(
        teacherId: teacherId,
        subject: subject,
        topic: teacherMemory.getPreference('currentLesson') ?? 'Unknown Topic',
        visualContent: _currentVisual!,
        explanation: _currentExplanation!,
        language: 'hindi', // Default to Hindi for rural context
        gradeLevel: gradeLevel,
        aiGenerated: true,
      );
      
      print('[VisualAidGeneratorAgent] Visual aid saved to Firestore successfully');
    } catch (e) {
      print('[VisualAidGeneratorAgent] Error saving to Firestore: $e');
    }
    
    _isGenerating = false;
    print('[VisualAidGeneratorAgent] Visual aid delivery complete');
  }

  @override
  Future<void> learn() async {
    print('[VisualAidGeneratorAgent] Learning: Recording visual aid effectiveness...');
    
    // Track visual generation analytics
    final visualHistory = teacherMemory.getPreference('visualHistory') ?? <Map<String, dynamic>>[];
    visualHistory.add({
      'timestamp': DateTime.now().toIso8601String(),
      'subject': teacherMemory.getPreference('currentSubject'),
      'lesson': teacherMemory.getPreference('currentLesson'),
      'visual': _currentVisual,
      'explanation': _currentExplanation,
      'gradeLevel': teacherMemory.getPreference('gradeLevel'),
    });
    
    teacherMemory.setPreference('visualHistory', visualHistory);
    
    // Update teacher preferences based on usage patterns
    final subject = teacherMemory.getPreference('currentSubject') ?? 'math';
    final subjectVisualCount = teacherMemory.getPreference('${subject}_visualCount') ?? 0;
    teacherMemory.setPreference('${subject}_visualCount', subjectVisualCount + 1);
    
    print('[VisualAidGeneratorAgent] Learning complete: Visual aid analytics updated');
  }

  // Helper methods
  bool _detectVisualNeed(String subject, dynamic lesson) {
    if (lesson == null) return false;
    
    final lessonStr = lesson.toString().toLowerCase();
    final visualKeywords = {
      'math': ['number', 'addition', 'subtraction', 'multiplication', 'division', 'fraction', 'geometry', 'shape'],
      'science': ['cycle', 'system', 'process', 'diagram', 'structure', 'parts', 'flow'],
      'english': ['grammar', 'sentence', 'structure', 'parts', 'punctuation'],
      'hindi': ['व्याकरण', 'वाक्य', 'संरचना', 'भाग', 'वर्णमाला'],
    };
    
    final keywords = visualKeywords[subject] ?? [];
    return keywords.any((keyword) => lessonStr.contains(keyword));
  }

  String _extractVisualFromAI(String aiResponse) {
    // Simple extraction - look for visual content markers
    if (aiResponse.contains('Visual:')) {
      final start = aiResponse.indexOf('Visual:') + 7;
      final end = aiResponse.indexOf('\n', start);
      return aiResponse.substring(start, end > start ? end : aiResponse.length).trim();
    }
    
    // Fallback to template
    return _generateTemplateVisual('math', 'Basic Concept');
  }

  String _extractExplanationFromAI(String aiResponse) {
    // Simple extraction - look for explanation content
    if (aiResponse.contains('Explanation:')) {
      final start = aiResponse.indexOf('Explanation:') + 12;
      return aiResponse.substring(start).trim();
    }
    
    return 'This visual helps you understand the concept clearly. Look at each part carefully.';
  }

  String _generateTemplateVisual(String subject, String lesson) {
    final templates = _visualTemplates[subject] ?? _visualTemplates['math']!;
    final randomIndex = DateTime.now().millisecond % templates.length;
    return templates[randomIndex];
  }

  String _generateTemplateExplanation(String subject, String lesson) {
    final explanations = {
      'math': 'यह गणित का एक महत्वपूर्ण अवधारणा है। इसे ध्यान से समझें।',
      'science': 'यह विज्ञान का एक बुनियादी सिद्धांत है। प्रक्रिया को समझें।',
      'english': 'यह अंग्रेजी व्याकरण का एक महत्वपूर्ण नियम है।',
      'hindi': 'यह हिंदी व्याकरण का एक महत्वपूर्ण नियम है।',
    };
    
    return explanations[subject] ?? explanations['math']!;
  }

  // Public getters for UI integration
  String? get currentVisual => _currentVisual;
  String? get currentExplanation => _currentExplanation;
  bool get isGenerating => _isGenerating;

  // Method to manually trigger visual generation
  Future<void> generateVisualForTopic(String subject, String topic) async {
    teacherMemory.setPreference('currentSubject', subject);
    teacherMemory.setPreference('currentLesson', topic);
    
    await runAgentCycle();
  }

  // Method to get visual history
  List<Map<String, dynamic>> getVisualHistory() {
    return teacherMemory.getPreference('visualHistory') ?? <Map<String, dynamic>>[];
  }

  // Method to clear visual history
  void clearVisualHistory() {
    teacherMemory.setPreference('visualHistory', <Map<String, dynamic>>[]);
  }
} 