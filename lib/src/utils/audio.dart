import 'package:audioplayers/audioplayers.dart';

class Audio {
  static final Audio _instance = Audio._internal();

  late AudioPlayer audioPlayer;
  AssetSource? _shakeBall;
  AssetSource? _pop;

  factory Audio() {
    return _instance;
  }

  Audio._internal() {
    audioPlayer = AudioPlayer();
    initSources();
  }

  void initSources() {
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
