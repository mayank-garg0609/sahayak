import 'package:flutter/material.dart';
import '../../agents/ask_me_later_agent.dart';
import '../../services/voice_service.dart';

class AskMeLaterPage extends StatefulWidget {
  final AskMeLaterAgent agent;

  const AskMeLaterPage({Key? key, required this.agent}) : super(key: key);

  @override
  State<AskMeLaterPage> createState() => _AskMeLaterPageState();
}

class _AskMeLaterPageState extends State<AskMeLaterPage> {
  final TextEditingController _controller = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  
  String? _answer;
  bool _loading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _speechResult = '';

  @override
  void initState() {
    super.initState();
    _initializeVoice();
    _setupVoiceStreams();
  }

  Future<void> _initializeVoice() async {
    await _voiceService.initialize();
  }

  void _setupVoiceStreams() {
    _voiceService.speechResultStream.listen((result) {
      setState(() {
        _speechResult = result;
        _controller.text = result;
      });
    });

    _voiceService.listeningStateStream.listen((isListening) {
      setState(() {
        _isListening = isListening;
      });
    });

    _voiceService.speakingStateStream.listen((isSpeaking) {
      setState(() {
        _isSpeaking = isSpeaking;
      });
    });
  }

  Future<void> _startVoiceInput() async {
    await widget.agent.perceive(isVoiceInput: true);
  }

  Future<void> _submitQuestion() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    
    setState(() {
      _loading = true;
      _answer = null;
    });
    
    await widget.agent.perceive(question: question);
    await widget.agent.plan();
    await widget.agent.act();
    await widget.agent.learn();
    
    setState(() {
      _answer = widget.agent.lastAnswer;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Me Later - Voice Enabled'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Voice Input Section
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic,
                          size: 32,
                          color: _isListening ? Colors.red : Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Voice Input',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isListening ? null : _startVoiceInput,
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      label: Text(_isListening ? 'Listening...' : 'Start Voice Input'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening ? Colors.red : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    if (_speechResult.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Heard: $_speechResult',
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Text Input Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Or Type Your Question',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Enter your question',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.edit),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _loading ? null : _submitQuestion,
              icon: _loading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send),
              label: Text(_loading ? 'Processing...' : 'Ask AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Answer Section
            if (_answer != null)
              Card(
                elevation: 6,
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.orange[600]),
                          const SizedBox(width: 8),
                          Text(
                            'AI Response',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _answer!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isSpeaking ? null : () => _voiceService.speak(_answer!),
                            icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_up_outlined),
                            label: Text(_isSpeaking ? 'Speaking...' : 'Hear Answer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isSpeaking ? _voiceService.stopSpeaking : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
} 