import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'api_manager.dart';
import 'gemini_interceptor.dart';

class AiService {
  late Dio _dio;
  late ApiKeyManager _keyManager;

  AiService() {
    _keyManager = ApiKeyManager()..loadKeys();
    _dio = Dio();
    _dio.interceptors.add(GeminiFailoverInterceptor(_keyManager, _dio));
  }

  Future<Map<String, dynamic>> analyzeImage(XFile photo, String mode) async {
    final Uint8List? imageBytes = await FlutterImageCompress.compressWithFile(
      photo.path,
      minWidth: 1024, minHeight: 1024, quality: 75, keepExif: false,
    );
    if (imageBytes == null) throw Exception("Image compression failed");
    final base64Image = base64Encode(imageBytes);

    final bool isPrescription = mode == 'Prescription';

    // ---------------------------------------------------------
    // DYNAMIC AI LOGIC: Visual Disease vs. Prescription Reader
    // ---------------------------------------------------------
    final systemInstruction = isPrescription
        ? "You are an expert pharmacist AI. Extract data from this prescription or medicine bottle. Translate complex medical jargon into simple, easy-to-understand language for a patient."
        : """You are an AI Visual Triage Assistant. 
Focus ONLY on these conditions: Ringworm, Psoriasis, Lyme Disease, Shingles, Hives, Conjunctivitis, Oral Thrush, Nail Clubbing.
CRITICAL SAFETY RULE: If this is a mole or pigmented lesion, you are FORBIDDEN from outputting 'Low Risk'. You must output 'Irregular - Consult Doctor'.""";

    final promptText = isPrescription
        ? "Read this prescription/label. Extract the medications, how to use them, and any side effects or warnings."
        : "Analyze this $mode image based on your instructions.";

    final schema = isPrescription
        ? { // PRESCRIPTION SCHEMA
            "type": "OBJECT",
            "properties": {
              "isValidPrescription": {"type": "BOOLEAN"},
              "medications": {"type": "STRING", "description": "Comma separated list of drugs"},
              "instructions": {"type": "STRING", "description": "How and when to take it, simplified"},
              "warnings": {"type": "STRING", "description": "Crucial warnings or side effects"}
            },
            "required": ["isValidPrescription", "medications", "instructions", "warnings"]
          }
        : { // VISUAL DISEASE SCHEMA
            "type": "OBJECT",
            "properties": {
              "isValidImage": {"type": "BOOLEAN"},
              "detectedCondition": {"type": "STRING"},
              "riskLevel": {"type": "STRING"},
              "whyDetected": {"type": "STRING"},
              "urgentAction": {"type": "STRING"}
            },
            "required": ["isValidImage", "detectedCondition", "riskLevel", "whyDetected", "urgentAction"]
          };

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent?key=${_keyManager.currentKey}';
    
    final response = await _dio.post(url, data: {
      "system_instruction": {"parts": [{"text": systemInstruction}]},
      "contents": [{
        "parts": [
          {"text": promptText},
          {"inlineData": {"mimeType": "image/jpeg", "data": base64Image}}
        ]
      }],
      "generationConfig": {
        "responseMimeType": "application/json",
        "responseSchema": schema
      }
    });

    final jsonString = response.data['candidates'][0]['content']['parts'][0]['text'];
    final result = jsonDecode(jsonString);
    
    // Add a helper flag so the UI knows which screen to show
    result['isPrescriptionMode'] = isPrescription; 
    return result;
  }
}