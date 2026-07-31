# Derma Lens AI

Derma Lens AI is a Flutter-powered intelligent skin and prescription analysis app that helps users capture or upload images and receive AI-assisted interpretation through Google Gemini.

It is designed for two primary use cases:

- **Skin condition triage** — analyze visible skin-related concerns from a photo
- **Prescription reading** — extract and simplify medication instructions from prescriptions or medicine labels

The app also includes:

- Camera capture support
- Gallery image selection
- AI-powered image analysis
- Text-to-speech output for accessibility
- Cross-platform Flutter support

## Features

### Skin Analysis
Upload or capture an image of a skin concern and receive AI-assisted feedback about likely visual conditions, risk level, and suggested next steps.

### Prescription Reading
Capture a prescription or medicine label and let the app extract:

- medication names
- usage instructions
- possible warnings or side effects

### Camera and Gallery Input
Users can analyze images directly from the camera or choose an image from the device gallery.

### Voice Output
The app can read results aloud using built-in text-to-speech support.

### Gemini-Based AI Workflow
Images are compressed and sent to Google Gemini for structured analysis using a JSON-based response format.

## Tech Stack

- **Flutter**
- **Dart**
- **Google Gemini API**
- **Camera**
- **Image Picker**
- **Dio**
- **flutter_dotenv**
- **flutter_image_compress**
- **flutter_tts**
- **flutter_riverpod**

## Project Structure

- `lib/main.dart` — app entry point and camera initialization
- `lib/home_screen.dart` — main UI and image analysis flow
- `lib/core/ai_service.dart` — Gemini API integration and image processing
- `assets/` — app assets and supporting data
- platform folders for Android, iOS, Web, Windows, macOS, and Linux

## Getting Started

### Prerequisites
- Flutter SDK
- Dart SDK
- A valid Google Gemini API key
- Device/emulator support for camera access if using photo capture

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Ibrahim71Reza/Derma-Lens-AI.git
   cd Derma-Lens-AI
   ```

2. Create a `.env` file in the project root and add your API key:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Configuration

This project loads environment variables from `.env` using `flutter_dotenv`.

If you plan to use camera features, make sure the required platform permissions are configured for:

- Android
- iOS
- Web
- Desktop platforms as applicable

## Important Disclaimer

Derma Lens AI is intended to provide informational and assistive AI output only.

It is **not a substitute for professional medical advice, diagnosis, or treatment**. Always consult a qualified healthcare professional for medical concerns, especially if symptoms are severe, worsening, or urgent.

## Notes

- The app compresses uploaded images before sending them to the AI service.
- AI responses are structured to return machine-readable JSON for easier UI handling.
- Results may vary depending on image quality and lighting.

## License

No license file was found in the repository.
