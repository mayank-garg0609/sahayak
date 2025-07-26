enum AgentEventType { idleStudent, newQuestion, feedbackReceived }

class AgentEvent {
  final AgentEventType type;
  final Map<String, dynamic> payload;
 
  AgentEvent({required this.type, required this.payload});
} 