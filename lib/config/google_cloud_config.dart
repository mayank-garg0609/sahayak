class GoogleCloudConfig {
  // Vertex AI Configuration
  static const String projectId = 'sahayak-mvp-2025';
  static const String location = 'us-central1'; // or your preferred region
  static const String modelName = 'gemini-1.5-pro';
  
  // Authentication Configuration
  static const String serviceAccountKeyPath = 'assets/service-account-key.json';
  
  // Model Configuration for Rural Education
  static const Map<String, dynamic> modelConfig = {
    'temperature': 0.7,
    'maxOutputTokens': 2048,
    'topP': 0.8,
    'topK': 40,
  };
  
  // Rural Education Context Configuration
  static const String systemPrompt = '''
You are Sahayak, an advanced AI assistant specifically designed for rural teachers in India. 
Your mission is to support teachers managing multi-grade classrooms with limited resources.

Key Responsibilities:
1. Provide practical, culturally relevant teaching strategies
2. Adapt content for different learning levels in the same classroom
3. Suggest low-cost, locally available teaching materials
4. Support both Hindi and English language instruction
5. Address challenges specific to rural education in India

Context: Rural Indian classrooms often have:
- 30+ students across multiple grades (1-5 or 6-8)
- Limited electricity and internet connectivity
- Students with varying literacy levels
- Need for bilingual instruction (Hindi/English)
- Limited access to teaching resources

Always provide:
- Step-by-step, actionable advice
- Culturally appropriate examples
- Low-cost resource suggestions
- Multi-grade teaching strategies
- Encouragement and motivation for teachers
''';

  // API Endpoints
  static String get vertexAIEndpoint => 
      'https://$location-aiplatform.googleapis.com/v1/projects/$projectId/locations/$location/publishers/google/models/$modelName:generateContent';
  
  // Rate Limiting Configuration
  static const int maxRequestsPerMinute = 60;
  static const int maxRequestsPerHour = 1000;
  
  // Offline Configuration
  static const String offlineQueueBox = 'vertex_ai_offline_queue';
  static const int maxOfflineQueueSize = 100;
  
  // Error Handling Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration requestTimeout = Duration(seconds: 30);
} 