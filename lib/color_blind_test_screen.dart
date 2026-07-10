import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- Data Model ---
class IshiharaPlate {
  final int id;
  final String imagePath;
  final String type;
  final String normalVision;
  final String protanDeficiency;
  final String deutanDeficiency;

  IshiharaPlate({required this.id, required this.imagePath, required this.type, required this.normalVision, required this.protanDeficiency, required this.deutanDeficiency});

  factory IshiharaPlate.fromJson(Map<String, dynamic> json) {
    return IshiharaPlate(
      id: json['plateId'],
      imagePath: json['imagePath'],
      type: json['type'],
      normalVision: json['normalVision'],
      protanDeficiency: json['protanDeficiency'],
      deutanDeficiency: json['deutanDeficiency'],
    );
  }
}

// --- The Screen ---
class ColorBlindTestScreen extends StatefulWidget {
  const ColorBlindTestScreen({super.key});

  @override
  State<ColorBlindTestScreen> createState() => _ColorBlindTestScreenState();
}

class _ColorBlindTestScreenState extends State<ColorBlindTestScreen> {
  List<IshiharaPlate> _testPlates = [];
  int _currentIndex = 0;
  final TextEditingController _textController = TextEditingController();

  // Scoring
  int _normalScore = 0;
  int _protanScore = 0;
  int _deutanScore = 0;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _loadAndRandomizeTest();
  }

  Future<void> _loadAndRandomizeTest() async {
    // 1. Load the JSON
    final String response = await rootBundle.loadString('assets/data/ishihara.json');
    final List<dynamic> data = jsonDecode(response);
    List<IshiharaPlate> allPlates = data.map((json) => IshiharaPlate.fromJson(json)).toList();

    // 2. Build a dynamic, randomized test (1 Demo + 5 Random)
    final demoPlate = allPlates.firstWhere((p) => p.type == 'demonstration');
    
    // Get random diagnostic plates and vanishing/transformation plates
    final otherPlates = allPlates.where((p) => p.type != 'demonstration').toList();
    otherPlates.shuffle(Random());
    
    // Create a 6-plate test sequence
    setState(() {
      _testPlates = [demoPlate, ...otherPlates.take(5)];
    });
  }

  void _submitAnswer(String answer) {
    final plate = _testPlates[_currentIndex];

    // Grade the answer
    if (answer == plate.normalVision) {
      _normalScore++;
    } else if (answer == plate.protanDeficiency) {
      _protanScore++;
    } else if (answer == plate.deutanDeficiency) {
      _deutanScore++;
    }

    // Move to next or finish
    if (_currentIndex < _testPlates.length - 1) {
      setState(() {
        _currentIndex++;
        _textController.clear();
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  Widget _buildResultScreen() {
    String diagnosis = "Normal Color Vision";
    String description = "You correctly identified the patterns. No signs of red-green color blindness.";
    Color color = Colors.greenAccent;

    // Logic for diagnosis based on scores
    if (_protanScore > 0 || _deutanScore > 0 || _normalScore <= 3) {
      if (_protanScore > _deutanScore) {
        diagnosis = "Possible Protanopia";
        description = "Your answers indicate a potential red-color vision deficiency. Please consult an optometrist.";
        color = Colors.redAccent;
      } else if (_deutanScore > _protanScore) {
        diagnosis = "Possible Deuteranopia";
        description = "Your answers indicate a potential green-color vision deficiency. Please consult an optometrist.";
        color = Colors.orangeAccent;
      } else {
        diagnosis = "General Red-Green Deficiency";
        description = "You showed signs of color blindness, but we couldn't isolate the exact type. Consult a professional.";
        color = Colors.orange;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility, size: 80, color: color),
          const SizedBox(height: 20),
          Text(diagnosis, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 12),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
            onPressed: () => Navigator.pop(context),
            child: const Text("Return to Camera", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_testPlates.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Ishihara Eye Test"), backgroundColor: Colors.black),
      body: _isFinished 
          ? _buildResultScreen()
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text("Plate ${_currentIndex + 1} of ${_testPlates.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 20),
                    
                    // Display the image
                    Container(
                      width: 300, height: 300,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.grey, width: 2)),
                      clipBehavior: Clip.hardEdge,
                      // Error builder in case the user hasn't added the image files yet
                      child: Image.asset(
                        _testPlates[_currentIndex].imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(child: Text("Image Missing", style: TextStyle(color: Colors.black))),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    const Text("What number do you see?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    // Input Field
                    TextField(
                      controller: _textController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "Enter number",
                        filled: true,
                        fillColor: Colors.blueGrey.withValues(alpha: 0.2),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Submit Button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: () {
                              if (_textController.text.isNotEmpty) _submitAnswer(_textController.text);
                            },
                            child: const Text("Submit", style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // "I see nothing" Button
                    TextButton(
                      onPressed: () => _submitAnswer("None"),
                      child: const Text("I see nothing", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}