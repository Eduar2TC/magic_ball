import 'package:audioplayers/audioplayers.dart';

class Audio {
  late AudioPlayer audioPlayer;
  AssetSource? _shakeBall;
  AssetSource? _pop;

  Audio() {
    audioPlayer = AudioPlayer();
    initSources();
  }

  initSources() {
    audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    audioPlayer.setVolume(1.0);
    _shakeBall = AssetSource('audio/ball/shake.mp3');
    _pop = AssetSource('audio/ball/pop.wav');
  }

  void playShake() {
    audioPlayer.stop().then((value) => audioPlayer.play(_shakeBall!));
  }

  void playPop() {
    audioPlayer.play(_pop!);
  }
}
