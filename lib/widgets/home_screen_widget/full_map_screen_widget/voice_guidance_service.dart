import 'package:flutter_tts/flutter_tts.dart';
import 'package:major_project/widgets/home_screen_widget/full_map_screen_widget/navigation_instruction.dart';


class VoiceGuidanceService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isMuted = false;

  VoiceGuidanceService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(NavigationInstruction instruction) async {
    if (_isMuted) return;
    await _flutterTts.speak(instruction.instruction);
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _flutterTts.stop();
    }
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}