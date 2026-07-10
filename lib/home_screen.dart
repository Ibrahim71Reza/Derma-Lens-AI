import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_tts/flutter_tts.dart'; // TTS Added!
import 'core/ai_service.dart';
import 'main.dart';
import 'color_blind_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  final AiService _aiService = AiService();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts(); // TTS Engine initialized
  
  String _selectedMode = 'Skin';
  bool _isAnalyzing = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initTTS();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);
      _controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  // Setup the voice speed and settings
  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slightly slower for medical clarity
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Stop talking when app closes
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    setState(() => _isFlashOn = !_isFlashOn);
    await _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _processImage(XFile photo) async {
    setState(() => _isAnalyzing = true);
    if (_isFlashOn) _toggleFlash(); 

    try {
      final result = await _aiService.analyzeImage(photo, _selectedMode);
      if (!mounted) return;
      _showResultBottomSheet(result);
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.response != null) {
        errorMessage = "Google API Error: ${e.response?.data}";
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("API Error"),
          content: Text(errorMessage),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        )
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final photo = await _controller!.takePicture();
    await _processImage(photo);
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) await _processImage(photo);
  }

  void _showResultBottomSheet(Map<String, dynamic> result) {
    final isRx = result['isPrescriptionMode'] == true;
    bool isSpeaking = false; // Tracks if audio is playing

    // Compile what the AI should say out loud
    final String textToSpeak = isRx 
        ? "Prescription Decoded. Medications: ${result['medications']}. How to use: ${result['instructions']}. Warnings: ${result['warnings']}."
        : "AI Assessment. Condition: ${result['detectedCondition']}. Risk Level: ${result['riskLevel']}. Reason: ${result['whyDetected']}. Recommended Action: ${result['urgentAction']}.";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      // StatefulBuilder lets the Play/Stop button update without rebuilding the whole screen
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          
          // Function to handle the Play/Stop button
          Future<void> toggleSpeech() async {
            if (isSpeaking) {
              await _flutterTts.stop();
              setModalState(() => isSpeaking = false);
            } else {
              setModalState(() => isSpeaking = true);
              _flutterTts.setCompletionHandler(() {
                if (mounted) setModalState(() => isSpeaking = false);
              });
              await _flutterTts.speak(textToSpeak);
            }
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Read Aloud Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isRx ? "Prescription Decoded" : "AI Assessment", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    Container(
                      decoration: BoxDecoration(color: isSpeaking ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up, color: isSpeaking ? Colors.red : Colors.blueAccent, size: 28),
                        onPressed: toggleSpeech,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                if (isRx) ...[
                  Text("Medications: ${result['medications']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 12),
                  Text("How to use: ${result['instructions']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text("Warnings: ${result['warnings']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ),
                ] else ...[
                  Text("Condition: ${result['detectedCondition']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Risk Level: ${result['riskLevel']}", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: result['riskLevel'] == 'High' ? Colors.redAccent : Colors.orangeAccent)),
                  const SizedBox(height: 12),
                  Text("Why: ${result['whyDetected']}", style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text("Action: ${result['urgentAction']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ),
                ],

                const SizedBox(height: 20),
                const Text("Disclaimer: This is an AI educational tool, not a medical diagnosis.", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                    onPressed: () => Navigator.pop(context), 
                    child: const Text("Done", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                  ),
                )
              ],
            ),
          );
        }
      )
    ).whenComplete(() => _flutterTts.stop()); // Stop talking automatically if user swipes the card down
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),
          // Ishihara Eye Test Button (Only visible in 'Eye' mode, moved down)
          if (_selectedMode == 'Eye')
            Positioned(
              top: 130, // Moved down so it doesn't overlap the top bar
              left: 20,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.8), // Made it blue so it stands out
                    child: IconButton(
                      icon: const Icon(Icons.remove_red_eye, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ColorBlindTestScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Color\nTest", 
                    textAlign: TextAlign.center, 
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])
                  ),
                ],
              ),
            ),
          Positioned(
            top: 50, right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: _isFlashOn ? Colors.yellow : Colors.white), onPressed: _toggleFlash),
            ),
          ),
          Center(
            child: Container(
              width: _selectedMode == 'Prescription' ? 300 : 250, 
              height: _selectedMode == 'Prescription' ? 150 : 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2), borderRadius: BorderRadius.circular(20)),
            ),
          ),
          Positioned(
            top: 60, left: 10, right: 70,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Skin', 'Eye', 'Nails', 'Mouth', 'Prescription'].map((mode) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(mode, style: const TextStyle(fontWeight: FontWeight.bold)),
                      selected: _selectedMode == mode,
                      selectedColor: mode == 'Prescription' ? Colors.deepPurpleAccent : Colors.blueAccent,
                      onSelected: (selected) => setState(() => _selectedMode = mode),
                    ),
                  )
                ).toList(),
              ),
            ),
          ),
          Positioned(
            bottom: 50, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  radius: 28, backgroundColor: Colors.black54,
                  child: IconButton(icon: const Icon(Icons.photo_library, color: Colors.white, size: 28), onPressed: _isAnalyzing ? null : _pickFromGallery),
                ),
                SizedBox(
                  height: 80, width: 80,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    onPressed: _isAnalyzing ? null : _takePhoto,
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 36),
                  ),
                ),
                const SizedBox(width: 56), 
              ],
            ),
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.blueAccent),
                    const SizedBox(height: 20),
                    Text(_selectedMode == 'Prescription' ? "Decoding medical text..." : "Analyzing visual markers...", 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}