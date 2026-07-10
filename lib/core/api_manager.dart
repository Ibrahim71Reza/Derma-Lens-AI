import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeyManager {
  List<String> _keys = [];
  int _currentIndex = 0;

  void loadKeys() {
    final keyString = dotenv.env['GEMINI_API_KEYS'] ?? '';
    _keys = keyString.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
    if (_keys.isEmpty) throw Exception('No API keys found in .env');
  }

  String get currentKey => _keys[_currentIndex];

  bool rotateKey() {
    if (_currentIndex < _keys.length - 1) {
      _currentIndex++;
      return true;
    }
    return false; // All keys exhausted
  }
}