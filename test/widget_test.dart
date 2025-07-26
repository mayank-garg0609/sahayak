// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sahayak_hello/main.dart';
import 'package:sahayak_hello/agents/agent_manager.dart';
import 'package:sahayak_hello/agents/whisper_mode_agent.dart';
import 'package:sahayak_hello/agents/ask_me_later_agent.dart';
import 'package:sahayak_hello/agents/visual_aid_generator_agent.dart';
import 'package:sahayak_hello/agents/memory/teacher_memory.dart';
import 'package:sahayak_hello/services/lesson_service.dart';
import 'package:sahayak_hello/services/voice_service.dart';
import 'package:sahayak_hello/services/ai_service.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      agentManager: AgentManager(),
      whisperModeAgent: WhisperModeAgent(
        teacherMemory: TeacherMemory(),
        lessonService: LessonService(),
        voiceService: VoiceService(),
        aiService: AIService(),
      ),
      askMeLaterAgent: AskMeLaterAgent(
        teacherMemory: TeacherMemory(),
        aiService: AIService(),
        voiceService: VoiceService(),
      ),
      visualAidGeneratorAgent: VisualAidGeneratorAgent(
        voiceService: VoiceService(),
        aiService: AIService(),
        teacherMemory: TeacherMemory(),
      ),
    ));

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
