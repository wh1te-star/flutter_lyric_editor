import 'package:flutter/material.dart';
import 'media_control_interface.dart';
import 'music_player_service.dart';

class VideoPane extends StatelessWidget implements MediaControlInterface {
  final MusicPlayerService musicPlayerService;

  VideoPane({required this.musicPlayerService});

  @override
  void onPlayPause() {
    musicPlayerService.onPlayPause();
    print("Play/Pause button tapped in the video_pane.dart");
  }

  @override
  void onChangeColor() {}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPlayPause();
      },
      child: Container(
        color: Colors.blue,
        child: Center(child: Text('Left Pane')),
      ),
    );
  }
}
