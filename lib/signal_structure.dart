class RequestPlayPause {}

class RequestGetIsPlaying {}

class RespondGetIsPlaying {
  final bool isPlaying;
  RespondGetIsPlaying(this.isPlaying);
}
