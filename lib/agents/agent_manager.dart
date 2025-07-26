import 'base_agent.dart';

class AgentManager {
  final List<BaseAgent> _agents = [];

  void registerAgent(BaseAgent agent) {
    _agents.add(agent);
  }

  Future<void> runAllAgents() async {
    for (final agent in _agents) {
      await agent.runAgentCycle();
    }
  }
} 