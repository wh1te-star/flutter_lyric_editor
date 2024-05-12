import 'package:audioplayers/audioplayers.dart';

class MusicPlayerService {
  AudioPlayer player = AudioPlayer();

  void play(Source url) {
    player.play(url);
  }

  void pause() {
    player.pause();
  }

  void stop() {
    player.stop();
  }

  void setVolume(double volume) {
    player.setVolume(volume);
  }

  //Stream<PlayerState> get playerStateStream => player.playerStateStream;
}
