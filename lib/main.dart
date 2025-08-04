import 'package:flutter/material.dart';
import 'package:lyric_editor/screen/top_screen_load_music.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Navigation Demo',
      home: HomeScreen(),
    );
  }
}