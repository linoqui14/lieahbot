import 'package:flutter_tts/flutter_tts.dart';


enum TtsState { playing, stopped, paused, continued }
class TTS{
  late FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  TTS(){

  }
  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }
  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future stop() async {
    var result = await flutterTts.stop();
    if (result == 1) ttsState = TtsState.stopped;
  }
  Future pause() async {
    var result = await flutterTts.pause();
    if (result == 1) ttsState = TtsState.paused;
  }
  Future speak(String message) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.speak(message);

  }

  void init({void onStart,void onComplete,void onError,void onCancel}){
    flutterTts = FlutterTts();
    _setAwaitOptions();
    _getDefaultEngine();
    flutterTts.setStartHandler(() {
      onStart;
    });

    flutterTts.setCompletionHandler(() {
      onComplete;
    });

    flutterTts.setCancelHandler(() {
      onCancel;
    });

    flutterTts.setErrorHandler((msg) {
      onError;
    });
  }
}