import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/signal_structure.dart';
import 'package:rxdart/rxdart.dart';
import 'appbar_menu.dart';
import 'music_player_service.dart';
import 'video_pane.dart';
import 'text_pane.dart';
import 'timeline_pane.dart';
import 'adjustable_pane_border.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: buildAppBarWithMenu(context),
        body: AdjustablePaneLayout(),
      ),
    );
  }
}

class ActivateIntent extends Intent {}

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

  final masterSubject = PublishSubject<dynamic>();
  late MusicPlayerService musicPlayerService;
  late FocusNode videoPaneFocusNode;
  late VideoPane videoPane;
  late TextPane textPane;
  late TimelinePane timelinePane;
  late AdjustablePaneBorder videoTextBorder;
  late AdjustablePaneBorder upperTimelineBorder;

  @override
  void initState() {
    super.initState();

    musicPlayerService = MusicPlayerService(masterSubject: masterSubject);
    videoPaneFocusNode = FocusNode();
    videoPane =
        VideoPane(masterSubject: masterSubject, focusNode: videoPaneFocusNode);
    textPane = TextPane(masterSubject: masterSubject);
    timelinePane = TimelinePane(masterSubject: masterSubject);
    videoTextBorder = AdjustablePaneBorder(
        child: Container(
          width: horizontalBorderWidth,
          color: Colors.grey,
        ),
        onHorizontalDragUpdate: (details) {
          setState(() {
            leftPaneWidth += details.delta.dx;
          });
        },
        onVerticalDragUpdate: (details) {});
    upperTimelineBorder = AdjustablePaneBorder(
        child: Container(
          height: verticalBorderHeight,
          color: Colors.grey,
        ),
        onHorizontalDragUpdate: (details) {},
        onVerticalDragUpdate: (details) {
          setState(() {
            bottomPaneHeight += details.delta.dy;
          });
        });

    musicPlayerService.initAudio('01 鬼願抄.mp3');
    musicPlayerService.play();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = 1000.0; //MediaQuery.of(context).size.width;
    screenHeight = 1000.0; //MediaQuery.of(context).size.height;
    exactWidth = screenWidth * MediaQuery.of(context).devicePixelRatio;
    exactHeight = screenHeight * MediaQuery.of(context).devicePixelRatio;
    leftPaneWidth = screenWidth;
    bottomPaneHeight = screenHeight / 2.0;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) => () {
              debugPrint('Shortcut is pressed.');
              masterSubject.add(RequestPlayPause());
            }(),
          ),
        },
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              children: <Widget>[
                Container(
                  height: bottomPaneHeight,
                  child: Row(
                    children: <Widget>[
                      Container(width: leftPaneWidth, child: videoPane),
                      videoTextBorder,
                      Expanded(child: textPane),
                    ],
                  ),
                ),
                upperTimelineBorder,
                Expanded(
                  child: timelinePane,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
