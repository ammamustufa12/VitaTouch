import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ThingAnnouncer {
  ThingAnnouncer({FlutterTts? voice}) : _voice = voice;

  static const _channel = MethodChannel('smart_health/buzzer');

  final FlutterTts? _voice;
  FlutterTts? _owned;
  int _token = 0;

  Future<void> announce(String speech) async {
    final token = ++_token;
    try {
      await _channel.invokeMethod<void>('beep');
    } catch (_) {}
    if (token != _token) {
      return;
    }
    try {
      final voice = await _engine();
      if (token != _token) {
        return;
      }
      await voice.speak(speech);
    } catch (_) {}
  }

  Future<void> stop() async {
    _token += 1;
    try {
      await (_owned ?? _voice)?.stop();
    } catch (_) {}
  }

  Future<FlutterTts> _engine() async {
    final voice = _voice ?? (_owned ??= FlutterTts());
    await voice.awaitSpeakCompletion(true);
    await voice.setLanguage('en-US');
    await voice.setSpeechRate(0.48);
    await voice.setVolume(1);
    await voice.setPitch(1);
    return voice;
  }
}
