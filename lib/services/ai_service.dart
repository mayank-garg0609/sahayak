import 'vertex_ai_service.dart';

class AIService {
  final VertexAIService _vertexAIService = VertexAIService();

  AIService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _vertexAIService.initialize();
  }

  Future<String> getAIAnswer(String question) async {
    return await _vertexAIService.getAIAnswer(question);
  }

  Future<void> processOfflineQueue() async {
    await _vertexAIService.processOfflineQueue();
  }

  Map<String, dynamic> getServiceStatus() {
    return _vertexAIService.getServiceStatus();
  }

  void dispose() {
    _vertexAIService.dispose();
  }
} 