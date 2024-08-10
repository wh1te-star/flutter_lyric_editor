import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'utility/appbar_menu.dart';
import 'pane/video_pane.dart';
import 'pane/text_pane.dart';
import 'pane/timeline_pane.dart';
import 'pane/adjustable_pane_border.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  late final KeyboardShortcutsProvider keyboardShortcutsProvider;
  late final MusicPlayerService musicPlayerProvider;
  late final TimingService timingProvider;
  late final TextPaneProvider textPaneProvider;
  late final TimelinePaneProvider timelinePaneProvider;
  late final VideoPaneProvider videoPaneProvider;

  @override
  Widget build(BuildContext context) {
    keyboardShortcutsProvider = KeyboardShortcutsProvider();
    musicPlayerProvider = MusicPlayerService(context: context);
    timingProvider = TimingService(context: context, musicPlayerProvider: musicPlayerProvider);
    textPaneProvider = TextPaneProvider(musicPlayerProvider: musicPlayerProvider, timingProvider: timingProvider);
    timelinePaneProvider = TimelinePaneProvider(musicPlayerProvider: musicPlayerProvider, timingProvider: timingProvider);
    videoPaneProvider = VideoPaneProvider(musicPlayerProvider: musicPlayerProvider, timingProvider: timingProvider);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (BuildContext context) => buildAppBarWithMenu(context, musicPlayerProvider, timingProvider),
          ),
        ),
        body: AdjustablePaneLayout(keyboardShortcutsProvider: keyboardShortcutsProvider, musicPlayerProvider: musicPlayerProvider, timingProvider: timingProvider, textPaneProvider: textPaneProvider, timelinePaneProvider: timelinePaneProvider, videoPaneProvider: videoPaneProvider),
      ),
    );
  }
}

class AdjustablePaneLayout extends StatefulWidget {
  final KeyboardShortcutsProvider keyboardShortcutsProvider;
  final MusicPlayerService musicPlayerProvider;
  final TimingService timingProvider;
  final TextPaneProvider textPaneProvider;
  final TimelinePaneProvider timelinePaneProvider;
  final VideoPaneProvider videoPaneProvider;

  AdjustablePaneLayout({
    required this.keyboardShortcutsProvider,
    required this.musicPlayerProvider,
    required this.timingProvider,
    required this.textPaneProvider,
    required this.timelinePaneProvider,
    required this.videoPaneProvider,
  }) : super(key: Key('Main'));

  @override
  _AdjustablePaneLayoutState createState() => _AdjustablePaneLayoutState(keyboardShortcutsProvider, musicPlayerProvider, timingProvider, textPaneProvider, timelinePaneProvider, videoPaneProvider);
}

class _AdjustablePaneLayoutState extends State<AdjustablePaneLayout> {
  final KeyboardShortcutsProvider keyboardShortcutsProvider;
  final MusicPlayerService musicPlayerProvider;
  final TimingService timingProvider;
  final TextPaneProvider textPaneProvider;
  final TimelinePaneProvider timelinePaneProvider;
  final VideoPaneProvider videoPaneProvider;

  _AdjustablePaneLayoutState(this.keyboardShortcutsProvider, this.musicPlayerProvider, this.timingProvider, this.textPaneProvider, this.timelinePaneProvider, this.videoPaneProvider);

  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double exactWidth = 0.0;
  double exactHeight = 0.0;

  double horizontalBorderWidth = 10;
  double verticalBorderHeight = 10;
  double LeftUpperPaneWidth = 100;
  double LeftUpperPaneHeight = 100;

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

    videoPaneFocusNode = FocusNode();
    textPaneFocusNode = FocusNode();
    timelinePaneFocusNode = FocusNode();

    musicPlayerService = MusicPlayerService(context: context);
    lyricService = TimingService(context: context, musicPlayerProvider: musicPlayerProvider);

    textPane = TextPane(focusNode: textPaneFocusNode, musicPlayerProvider: musicPlayerProvider, timingProvider: timingProvider, textPaneProvider: textPaneProvider, timelinePaneProvider: timelinePaneProvider);
    timelinePane = TimelinePane(focusNode: timelinePaneFocusNode, keyboardShortcutsProvider: keyboardShortcutsProvider, musicPlayerProvider: musicPlayerProvider, timingProvider: timingProvider, textPaneProvider: textPaneProvider, timelinePaneProvider: timelinePaneProvider);
    videoPane = VideoPane(focusNode: videoPaneFocusNode, keyboardShortcutsProvider: keyboardShortcutsProvider, musicPlayerProvider: musicPlayerProvider, timingProvider: timingProvider, textPaneProvider: textPaneProvider, timelinePaneProvider: timelinePaneProvider, videoPaneProvider: videoPaneProvider);

    videoTextBorder = AdjustablePaneBorder(
        child: Container(
          width: horizontalBorderWidth,
          color: Colors.grey,
        ),
        onHorizontalDragUpdate: (details) {
          setState(() {
            if (details.delta.dx > 0) {
              LeftUpperPaneWidth += details.delta.dx;
            } else {
              if (LeftUpperPaneWidth > videoPaneWidthlimit) {
                LeftUpperPaneWidth += details.delta.dx;
              } else {
                LeftUpperPaneWidth = videoPaneWidthlimit;
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
            LeftUpperPaneHeight += details.delta.dy;
          });
        });

    musicPlayerService.initAudio('assets/09 ウェルカムティーフレンド.mp3');
    musicPlayerService.play();

    lyricService.printLyric();

    //loadText();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    exactWidth = screenWidth * MediaQuery.of(context).devicePixelRatio;
    exactHeight = screenHeight * MediaQuery.of(context).devicePixelRatio;
    LeftUpperPaneWidth = screenWidth * 1.0 / 3.0;
    LeftUpperPaneHeight = screenHeight * 2.0 / 3.0;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardShortcuts(
      keyboardShortcutsProvider: keyboardShortcutsProvider,
      timingProvider: timingProvider,
      musicPlayerProvider: musicPlayerProvider,
      textPaneProvider: textPaneProvider,
      timelinePaneProvider: timelinePaneProvider,
      videoPaneProvider: videoPaneProvider,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              Container(
                height: LeftUpperPaneHeight,
                child: Row(
                  children: <Widget>[
                    Container(width: LeftUpperPaneWidth, child: textPane),
                    videoTextBorder,
                    Expanded(child: videoPane),
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
    );
  }
}
