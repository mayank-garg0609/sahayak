import 'package:flutter/material.dart';
import '../../agents/visual_aid_generator_agent.dart';
import '../../services/voice_service.dart';

class VisualAidPage extends StatefulWidget {
  final VisualAidGeneratorAgent agent;
  final VoiceService voiceService;

  const VisualAidPage({
    Key? key,
    required this.agent,
    required this.voiceService,
  }) : super(key: key);

  @override
  State<VisualAidPage> createState() => _VisualAidPageState();
}

class _VisualAidPageState extends State<VisualAidPage> {
  String selectedSubject = 'math';
  String selectedTopic = '';
  bool isGenerating = false;
  bool isSpeaking = false;

  final Map<String, List<String>> subjectTopics = {
    'math': [
      'Addition and Subtraction',
      'Multiplication Tables',
      'Fractions',
      'Place Value',
      'Geometry Shapes',
      'Number Line',
    ],
    'science': [
      'Water Cycle',
      'Plant Life Cycle',
      'Solar System',
      'Food Chain',
      'States of Matter',
      'Human Body Parts',
    ],
    'english': [
      'Parts of Speech',
      'Sentence Structure',
      'Punctuation',
      'Tenses',
      'Synonyms and Antonyms',
      'Reading Comprehension',
    ],
    'hindi': [
      'वर्णमाला',
      'संज्ञा और सर्वनाम',
      'क्रिया',
      'विशेषण',
      'लिंग और वचन',
      'मुहावरे',
    ],
  };

  @override
  void initState() {
    super.initState();
    selectedTopic = subjectTopics[selectedSubject]!.first;
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    await widget.voiceService.initialize();
  }

  Future<void> _generateVisual() async {
    setState(() {
      isGenerating = true;
    });

    try {
      await widget.agent.generateVisualForTopic(selectedSubject, selectedTopic);
      
      // Update teacher memory with current context
      widget.agent.teacherMemory.setPreference('currentSubject', selectedSubject);
      widget.agent.teacherMemory.setPreference('currentLesson', selectedTopic);
      
      setState(() {
        isGenerating = false;
      });
    } catch (e) {
      setState(() {
        isGenerating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating visual: $e')),
      );
    }
  }

  Future<void> _speakExplanation() async {
    if (widget.agent.currentExplanation == null) return;

    setState(() {
      isSpeaking = true;
    });

    try {
      await widget.voiceService.speak(widget.agent.currentExplanation!);
    } finally {
      setState(() {
        isSpeaking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 Visual Aid Generator'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.purple],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subject Selection Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📚 Select Subject',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedSubject,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Subject',
                          ),
                          items: subjectTopics.keys.map((subject) {
                            return DropdownMenuItem(
                              value: subject,
                              child: Text(subject.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSubject = value!;
                              selectedTopic = subjectTopics[value]!.first;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Topic Selection Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎯 Select Topic',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedTopic,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Topic',
                          ),
                          items: subjectTopics[selectedSubject]!.map((topic) {
                            return DropdownMenuItem(
                              value: topic,
                              child: Text(topic),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTopic = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Generate Button
                ElevatedButton.icon(
                  onPressed: isGenerating ? null : _generateVisual,
                  icon: isGenerating 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                  label: Text(isGenerating ? 'Generating...' : 'Generate Visual Aid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Visual Display Card
                Expanded(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '🎨 Generated Visual',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              if (widget.agent.currentVisual != null)
                                IconButton(
                                  onPressed: isSpeaking ? null : _speakExplanation,
                                  icon: Icon(
                                    isSpeaking ? Icons.volume_off : Icons.volume_up,
                                    color: isSpeaking ? Colors.grey : Colors.deepPurple,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: widget.agent.currentVisual != null
                                ? SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Visual Content
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue[200]!),
                                          ),
                                          child: Text(
                                            widget.agent.currentVisual!,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'monospace',
                                              height: 1.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        
                                        // Explanation
                                        if (widget.agent.currentExplanation != null) ...[
                                          const Text(
                                            '📝 Explanation:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              widget.agent.currentExplanation!,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No visual generated yet.\nSelect a topic and generate!',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 