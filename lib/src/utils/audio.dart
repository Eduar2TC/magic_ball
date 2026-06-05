import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class Audio {
  static final Audio _instance = Audio._internal();
  factory Audio() => _instance;

  late final AudioPlayer _shakePlayer;
  late final AudioPlayer _popPlayer;

  Audio._internal() {
    _shakePlayer = AudioPlayer();
    _popPlayer = AudioPlayer();

    // Precarga de audios desde assets
    _loadAudioAssets();
    
    _shakePlayer.setVolume(1.0);
    _popPlayer.setVolume(1.0);
  }

  Future<void> _loadAudioAssets() async {
    try {
      await _shakePlayer.setAsset('assets/audio/ball/shake.wav');
      await _popPlayer.setAsset('assets/audio/ball/pop.wav');
    } catch (e) {
      debugPrint('❌ Error al cargar audios: $e');
    }
  }

  void startShakeLoop() async {
    await _shakePlayer.setLoopMode(LoopMode.one);
    await _shakePlayer.play();
  }

  void stopShakeLoop() {
    _shakePlayer.pause();
    _shakePlayer.seek(Duration.zero);
  }

  void playShakeOneShot() async {
    await _shakePlayer.setLoopMode(LoopMode.off);
    await _shakePlayer.seek(Duration.zero);
    await _shakePlayer.play();
  }

  void playPop() async {
    debugPrint('🔊 [AUDIO] Disparando sonido POP');
    await _popPlayer.seek(Duration.zero);
    await _popPlayer.play();
  }

  void dispose() {
    _shakePlayer.dispose();
    _popPlayer.dispose();
  }
}