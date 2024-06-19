import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/timing_service.dart';
import 'package:lyric_editor/signal_structure.dart';
import 'package:rxdart/rxdart.dart';
import 'appbar_menu.dart';
import 'music_player_service.dart';
import 'video_pane.dart';
import 'text_pane.dart';
import 'timeline_pane.dart';
import 'adjustable_pane_border.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final masterSubject = PublishSubject<dynamic>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (BuildContext context) =>
                buildAppBarWithMenu(context, masterSubject),
          ),
        ),
        body: AdjustablePaneLayout(masterSubject: masterSubject),
      ),
    );
  }
}

class AdjustablePaneLayout extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;

  AdjustablePaneLayout({required this.masterSubject}) : super(key: Key('Main'));

  @override
  _AdjustablePaneLayoutState createState() =>
      _AdjustablePaneLayoutState(masterSubject);
}

class _AdjustablePaneLayoutState extends State<AdjustablePaneLayout> {
  final PublishSubject<dynamic> masterSubject;
  _AdjustablePaneLayoutState(this.masterSubject);

  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double exactWidth = 0.0;
  double exactHeight = 0.0;

  double horizontalBorderWidth = 10;
  double verticalBorderHeight = 10;
  double VideoPaneWidth = 100;
  double VideoPaneHeight = 100;

  late MusicPlayerService musicPlayerService;
  late TimingService lyricService;
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
    lyricService = TimingService(masterSubject: masterSubject);
    videoPaneFocusNode = FocusNode();
    textPaneFocusNode = FocusNode();
    timelinePaneFocusNode = FocusNode();
    videoPane = VideoPane(
      masterSubject: masterSubject,
      focusNode: videoPaneFocusNode,
    );
    textPane = TextPane(
      masterSubject: masterSubject,
      focusNode: videoPaneFocusNode,
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

    musicPlayerService.initAudio('assets/09 ウェルカムティーフレンド.mp3');
    musicPlayerService.play();

    lyricService.printLyric();
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
        LogicalKeySet(LogicalKeyboardKey.keyD): ActivateRewindIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyF): ActivateForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): ActivateSpeedDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): ActivateSpeedUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): ActivateVolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): ActivateVolumeDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyH): ActivateMoveLeftCursor(),
        LogicalKeySet(LogicalKeyboardKey.keyJ): ActivateMoveDownCursor(),
        LogicalKeySet(LogicalKeyboardKey.keyK): ActivateMoveUpCursor(),
        LogicalKeySet(LogicalKeyboardKey.keyL): ActivateMoveRightCursor(),
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyK):
            ActivateTimelineZoomIn(),
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyJ):
            ActivateTimelineZoomOut(),
        LogicalKeySet(LogicalKeyboardKey.keyL): ActivateMoveRightCursor(),
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
          ActivateMoveLeftCursor: CallbackAction<ActivateMoveLeftCursor>(
            onInvoke: (ActivateMoveLeftCursor intent) => () {
              masterSubject.add(RequestMoveLeftCharCursor());
            }(),
          ),
          ActivateMoveDownCursor: CallbackAction<ActivateMoveDownCursor>(
            onInvoke: (ActivateMoveDownCursor intent) => () {
              masterSubject.add(RequestMoveDownCharCursor());
            }(),
          ),
          ActivateMoveUpCursor: CallbackAction<ActivateMoveUpCursor>(
            onInvoke: (ActivateMoveUpCursor intent) => () {
              masterSubject.add(RequestMoveUpCharCursor());
            }(),
          ),
          ActivateMoveRightCursor: CallbackAction<ActivateMoveRightCursor>(
            onInvoke: (ActivateMoveRightCursor intent) => () {
              masterSubject.add(RequestMoveRightCharCursor());
            }(),
          ),
          ActivateTimelineZoomIn: CallbackAction<ActivateTimelineZoomIn>(
            onInvoke: (ActivateTimelineZoomIn intent) => () {
              masterSubject.add(RequestTimelineZoomIn());
            }(),
          ),
          ActivateTimelineZoomOut: CallbackAction<ActivateTimelineZoomOut>(
            onInvoke: (ActivateTimelineZoomOut intent) => () {
              masterSubject.add(RequestTimelineZoomOut());
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

class ActivateMoveDownCursor extends Intent {}

class ActivateMoveUpCursor extends Intent {}

class ActivateMoveLeftCursor extends Intent {}

class ActivateMoveRightCursor extends Intent {}

class ActivateTimelineZoomIn extends Intent {}

class ActivateTimelineZoomOut extends Intent {}
