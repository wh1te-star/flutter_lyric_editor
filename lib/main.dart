import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'music_player_service.dart';
import 'video_pane.dart';
import 'text_pane.dart';
import 'adjustable_pane_border.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AdjustablePaneLayout(),
      ),
    );
  }
}

class AdjustablePaneLayout extends StatefulWidget {
  @override
  _AdjustablePaneLayoutState createState() => _AdjustablePaneLayoutState();
}

class _AdjustablePaneLayoutState extends State<AdjustablePaneLayout> {
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double exactWidth = 0.0;
  double exactHeight = 0.0;

  double horizontalBorderWidth = 10;
  double verticalBorderHeight = 10;
  double leftPaneWidth = 100;
  double bottomPaneHeight = 100;

  MusicPlayerService musicPlayerService = MusicPlayerService();

  @override
  void initState() {
    super.initState();
    musicPlayerService.initAudio('01 鬼願抄.mp3');
    musicPlayerService.play();
    /*
    musicPlayerService.playerStateStream.listen((state) {
      switch (state) {
        case PlayerState.playing:
          print("Playing...");
          break;
        case PlayerState.paused:
          print("Paused");
          break;
        case PlayerState.completed:
          print("Completed");
          break;
        default:
          print("Unknown state");
      }
    });
    */
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = 1000.0; //MediaQuery.of(context).size.width;
    screenHeight = 1000.0; //MediaQuery.of(context).size.height;
    exactWidth = screenWidth * MediaQuery.of(context).devicePixelRatio;
    exactHeight = screenHeight * MediaQuery.of(context).devicePixelRatio;
    leftPaneWidth = screenWidth / 2.0;
    bottomPaneHeight = screenHeight / 2.0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          children: <Widget>[
            Container(
              height: bottomPaneHeight,
              child: Row(
                children: <Widget>[
                  Container(
                      width: leftPaneWidth,
                      child: VideoPane(musicPlayerService: musicPlayerService)),
                  AdjustablePaneBorder(
                      child: Container(
                        width: horizontalBorderWidth,
                        color: Colors.grey,
                      ),
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          leftPaneWidth += details.delta.dx;
                        });
                      },
                      onVerticalDragUpdate: (details) {}),
                  Expanded(child: TextPane()),
                ],
              ),
            ),
            AdjustablePaneBorder(
                child: Container(
                  height: verticalBorderHeight,
                  color: Colors.grey,
                ),
                onHorizontalDragUpdate: (details) {},
                onVerticalDragUpdate: (details) {
                  setState(() {
                    bottomPaneHeight += details.delta.dy;
                  });
                }),
            Expanded(
              child: Container(
                color: Colors.red,
                child: Center(child: Text('bottom Pane')),
              ),
            ),
          ],
        );
      },
    );
  }
}
