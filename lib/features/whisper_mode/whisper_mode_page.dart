import 'package:flutter/material.dart';
import '../../agents/whisper_mode_agent.dart';

class WhisperModePage extends StatefulWidget {
  final WhisperModeAgent agent;

  const WhisperModePage({Key? key, required this.agent}) : super(key: key);

  @override
  State<WhisperModePage> createState() => _WhisperModePageState();
}

class _WhisperModePageState extends State<WhisperModePage> {
  Map<String, dynamic>? _lesson;
  bool _isPlaying = false;

  Future<void> _triggerWhisperMode() async {
    setState(() {
      _isPlaying = true;
      _lesson = null;
    });
    await widget.agent.runAgentCycle();
    setState(() {
      _lesson = widget.agent.selectedLesson;
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whisper Mode'),
      ),
      body: Center(
        child: _isPlaying
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Playing audio...'),
                ],
              )
            : _lesson != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _lesson!['title'] ?? 'No Title',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Subject:  [1m${_lesson!['subject'] ?? 'N/A'} [0m'),
                      Text('Grade: ${_lesson!['grade'] ?? 'N/A'}'),
                      Text('Duration: ${_lesson!['duration'] ?? 'N/A'}'),
                      const SizedBox(height: 16),
                      Text(_lesson!['content'] ?? 'No Content'),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _triggerWhisperMode,
                        child: const Text('Deliver Another Lesson'),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _triggerWhisperMode,
                    child: const Text('Start Whisper Mode'),
                  ),
      ),
    );
  }
} 