import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'agents/agent_manager.dart';
import 'agents/test_agent.dart';
import 'agents/whisper_mode_agent.dart';
import 'agents/ask_me_later_agent.dart';
import 'agents/visual_aid_generator_agent.dart';
import 'agents/memory/teacher_memory.dart';
import 'services/lesson_service.dart';
import 'services/ai_service.dart';
import 'services/voice_service.dart';
import 'services/vertex_ai_service.dart';
import 'features/whisper_mode/whisper_mode_page.dart';
import 'features/ask_me_later/ask_me_later_page.dart';
import 'features/visual_aid/visual_aid_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Google Cloud services
  final vertexAIService = VertexAIService();
  await vertexAIService.initialize();
  
  final voiceService = VoiceService();
  await voiceService.initialize();

  final agentManager = AgentManager();
  final testAgent = TestAgent();
  agentManager.registerAgent(testAgent);

  final teacherMemory = TeacherMemory();
  final lessonService = LessonService();
  final aiService = AIService();
  
  final whisperModeAgent = WhisperModeAgent(
    teacherMemory: teacherMemory,
    lessonService: lessonService,
    voiceService: voiceService,
    aiService: aiService,
  );
  agentManager.registerAgent(whisperModeAgent);

                final askMeLaterAgent = AskMeLaterAgent(
                teacherMemory: teacherMemory,
                aiService: aiService,
                voiceService: voiceService,
              );
              agentManager.registerAgent(askMeLaterAgent);

              final visualAidGeneratorAgent = VisualAidGeneratorAgent(
                voiceService: voiceService,
                aiService: aiService,
                teacherMemory: teacherMemory,
              );
              agentManager.registerAgent(visualAidGeneratorAgent);

              runApp(MyApp(
                agentManager: agentManager,
                whisperModeAgent: whisperModeAgent,
                askMeLaterAgent: askMeLaterAgent,
                visualAidGeneratorAgent: visualAidGeneratorAgent,
              ));
}

class MyApp extends StatelessWidget {
  final AgentManager agentManager;
  final WhisperModeAgent whisperModeAgent;
  final AskMeLaterAgent askMeLaterAgent;
  final VisualAidGeneratorAgent visualAidGeneratorAgent;
  const MyApp({
    super.key,
    required this.agentManager,
    required this.whisperModeAgent,
    required this.askMeLaterAgent,
    required this.visualAidGeneratorAgent,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahayak Hello',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: 'Sahayak - Rural Education AI Assistant',
        agentManager: agentManager,
        whisperModeAgent: whisperModeAgent,
        askMeLaterAgent: askMeLaterAgent,
        visualAidGeneratorAgent: visualAidGeneratorAgent,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final AgentManager agentManager;
  final WhisperModeAgent whisperModeAgent;
  final AskMeLaterAgent askMeLaterAgent;
  final VisualAidGeneratorAgent visualAidGeneratorAgent;

  const MyHomePage({
    super.key,
    required this.title,
    required this.agentManager,
    required this.whisperModeAgent,
    required this.askMeLaterAgent,
    required this.visualAidGeneratorAgent,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _testFirestore() async {
  try {
    print('=== TESTING FIRESTORE CONNECTION ===');
    
    // Clear any existing offline cache and force fresh data
    await FirebaseFirestore.instance.clearPersistence();
    
    // Force fresh data from server only
    var snapshot = await FirebaseFirestore.instance
        .collection('lessons')
        .get(const GetOptions(source: Source.server));
    
    print('SUCCESS: Found ${snapshot.docs.length} lessons from server');
    
    if (snapshot.docs.isEmpty) {
      print('STILL EMPTY: Trying from cache as fallback...');
      snapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .get(const GetOptions(source: Source.cache));
      print('CACHE: Found ${snapshot.docs.length} lessons from cache');
    }
    
    int count = 1;
    for (var doc in snapshot.docs) {
      print('--- LESSON $count ---');
      print('Title: ${doc.data()['title'] ?? 'No title'}');
      print('Subject: ${doc.data()['subject'] ?? 'No subject'}');
      print('Grade: ${doc.data()['grade'] ?? 'No grade'}');
      print('Duration: ${doc.data()['duration'] ?? 'No duration'}');
      count++;
    }
    print('=== FIRESTORE TEST COMPLETE ===');
  } catch (e) {
    print('ERROR: Firestore failed - $e');
    print('Trying offline mode as fallback...');
    try {
      var snapshot = await FirebaseFirestore.instance.collection('lessons').get();
      print('OFFLINE SUCCESS: Found ${snapshot.docs.length} lessons');
    } catch (e2) {
      print('OFFLINE ALSO FAILED: $e2');
    }
  }
}

  void _runTestAgents() async {
    await widget.agentManager.runAllAgents();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TestAgent lifecycle executed. Check console output.')),
    );
  }

  void _openWhisperMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WhisperModePage(agent: widget.whisperModeAgent),
      ),
    );
  }

  void _openAskMeLater() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AskMeLaterPage(agent: widget.askMeLaterAgent),
      ),
    );
  }

  void _openVisualAidGenerator() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VisualAidPage(
          agent: widget.visualAidGeneratorAgent,
          voiceService: VoiceService(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _runTestAgents,
              child: const Text('Test Agents'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openWhisperMode,
              child: const Text('Open Whisper Mode'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openAskMeLater,
              child: const Text('Ask Me Later'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openVisualAidGenerator,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('🎨 Visual Aid Generator'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "firebase_test",
            onPressed: _testFirestore,
            tooltip: 'Test Firebase',
            child: const Icon(Icons.cloud),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "increment",
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
