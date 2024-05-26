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
  double VideoPaneWidth = 100;
  double VideoPaneHeight = 100;

  final masterSubject = PublishSubject<dynamic>();
  late MusicPlayerService musicPlayerService;
  late FocusNode videoPaneFocusNode;
  late FocusNode textPaneFocusNode;
  late FocusNode timelinePaneFocusNode;
  late VideoPane videoPane;
  late TextPane textPane;
  late TimelinePane timelinePane;
  late AdjustablePaneBorder videoTextBorder;
  late AdjustablePaneBorder upperTimelineBorder;

  double videoPaneWidthlimit = 1000.0;

  @override
  void initState() {
    super.initState();

    musicPlayerService = MusicPlayerService(masterSubject: masterSubject);
    videoPaneFocusNode = FocusNode();
    textPaneFocusNode = FocusNode();
    timelinePaneFocusNode = FocusNode();
    videoPane = VideoPane(
      masterSubject: masterSubject,
      focusNode: videoPaneFocusNode,
    );
    textPane = TextPane(
      masterSubject: masterSubject,
      focusNode: textPaneFocusNode,
    );
    timelinePane = TimelinePane(
      masterSubject: masterSubject,
      focusNode: timelinePaneFocusNode,
    );
    videoTextBorder = AdjustablePaneBorder(
        child: Container(
          width: horizontalBorderWidth,
          color: Colors.grey,
        ),
        onHorizontalDragUpdate: (details) {
          setState(() {
            if (details.delta.dx > 0) {
              VideoPaneWidth += details.delta.dx;
            } else {
              if (VideoPaneWidth > videoPaneWidthlimit) {
                VideoPaneWidth += details.delta.dx;
              } else {
                VideoPaneWidth = videoPaneWidthlimit;
              }
            }
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
            VideoPaneHeight += details.delta.dy;
          });
        });

    masterSubject.listen((signal) {
      if (signal is NotifyVideoPaneWidthLimit) {
        videoPaneWidthlimit = signal.widthLimit;
      }
    });

    musicPlayerService.initAudio('01 鬼願抄.mp3');
    musicPlayerService.play();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    exactWidth = screenWidth * MediaQuery.of(context).devicePixelRatio;
    exactHeight = screenHeight * MediaQuery.of(context).devicePixelRatio;
    VideoPaneWidth = screenWidth * 2.0 / 3.0;
    VideoPaneHeight = screenHeight * 2.0 / 3.0;
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.space): ActivatePlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyH): ActivateRewindIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyL): ActivateForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): ActivateSpeedDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): ActivateSpeedUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): ActivateVolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): ActivateVolumeDownIntent(),
      },
      child: Actions(
        actions: {
          ActivatePlayPauseIntent: CallbackAction<ActivatePlayPauseIntent>(
            onInvoke: (ActivatePlayPauseIntent intent) => () {
              masterSubject.add(RequestPlayPause());
            }(),
          ),
          ActivateRewindIntent: CallbackAction<ActivateRewindIntent>(
            onInvoke: (ActivateRewindIntent intent) => () {
              masterSubject.add(RequestRewind(1000));
            }(),
          ),
          ActivateForwardIntent: CallbackAction<ActivateForwardIntent>(
            onInvoke: (ActivateForwardIntent intent) => () {
              masterSubject.add(RequestForward(1000));
            }(),
          ),
          ActivateVolumeUpIntent: CallbackAction<ActivateVolumeUpIntent>(
            onInvoke: (ActivateVolumeUpIntent intent) => () {
              masterSubject.add(RequestVolumeUp(0.1));
            }(),
          ),
          ActivateVolumeDownIntent: CallbackAction<ActivateVolumeDownIntent>(
            onInvoke: (ActivateVolumeDownIntent intent) => () {
              masterSubject.add(RequestVolumeDown(0.1));
            }(),
          ),
          ActivateSpeedUpIntent: CallbackAction<ActivateSpeedUpIntent>(
            onInvoke: (ActivateSpeedUpIntent intent) => () {
              masterSubject.add(RequestSpeedUp(0.1));
            }(),
          ),
          ActivateSpeedDownIntent: CallbackAction<ActivateSpeedDownIntent>(
            onInvoke: (ActivateSpeedDownIntent intent) => () {
              masterSubject.add(RequestSpeedDown(0.1));
            }(),
          ),
        },
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              children: <Widget>[
                Container(
                  height: VideoPaneHeight,
                  child: Row(
                    children: <Widget>[
                      Container(width: VideoPaneWidth, child: videoPane),
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

class ActivatePlayPauseIntent extends Intent {}

class ActivateForwardIntent extends Intent {}

class ActivateRewindIntent extends Intent {}

class ActivateVolumeUpIntent extends Intent {}

class ActivateVolumeDownIntent extends Intent {}

class ActivateSpeedUpIntent extends Intent {}

class ActivateSpeedDownIntent extends Intent {}
