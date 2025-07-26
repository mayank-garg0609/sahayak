abstract class BaseAgent {
  /// Called to detect triggers or events in the environment.
  Future<void> perceive();

  /// Called to decide what actions to take based on perception and memory.
  Future<void> plan();

  /// Called to execute the planned actions.
  Future<void> act();

  /// Called to update memory or learn from outcomes.
  Future<void> learn();

  /// Optionally, a method to run the full agent loop.
  Future<void> runAgentCycle() async {
    await perceive();
    await plan();
    await act();
    await learn();
  }
} 