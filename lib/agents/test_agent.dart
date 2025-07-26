import 'base_agent.dart';

class TestAgent extends BaseAgent {
  @override
  Future<void> perceive() async {
    print('[TestAgent] perceive() called');
  }

  @override
  Future<void> plan() async {
    print('[TestAgent] plan() called');
  }

  @override
  Future<void> act() async {
    print('[TestAgent] act() called');
  }

  @override
  Future<void> learn() async {
    print('[TestAgent] learn() called');
  }
} 