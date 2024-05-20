class RequestPlayPause {}

class RequestRewind {
  int millisec;
  RequestRewind(this.millisec);
}

class NotifyIsPlaying {
  bool isPlaying;
  NotifyIsPlaying(this.isPlaying);
}

class NotifySeekPosition {
  int seekPosition;
  NotifySeekPosition(this.seekPosition);
}
