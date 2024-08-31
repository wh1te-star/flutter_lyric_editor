import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'utility/appbar_menu.dart';
import 'service/music_player_service.dart';
import 'pane/video_pane.dart';
import 'pane/text_pane.dart';
import 'pane/timeline_pane.dart';
import 'pane/adjustable_pane_border.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (BuildContext context) => buildAppBarWithMenu(
              context,
              musicPlayerService,
              timingService,
            ),
          ),
        ),
        body: AdjustablePaneLayout(),
      ),
    );
  }
}

class AdjustablePaneLayout extends ConsumerStatefulWidget {
  AdjustablePaneLayout() : super(key: Key('Main'));

  @override
  _AdjustablePaneLayoutState createState() => _AdjustablePaneLayoutState();
}

class _AdjustablePaneLayoutState extends ConsumerState<AdjustablePaneLayout> {
  _AdjustablePaneLayoutState();

  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double exactWidth = 0.0;
  double exactHeight = 0.0;

  double horizontalBorderWidth = 10;
  double verticalBorderHeight = 10;
  double LeftUpperPaneWidth = 100;
  double LeftUpperPaneHeight = 100;

  late MusicPlayerService musicPlayerService;
  late TimingService timingService;
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

    musicPlayerService = ref.read(musicPlayerMasterProvider);
    timingService = TimingService(
      musicPlayerProvider: musicPlayerService,
    );
    videoPaneFocusNode = FocusNode();
    textPaneFocusNode = FocusNode();
    timelinePaneFocusNode = FocusNode();
    videoPane = VideoPane(
      focusNode: videoPaneFocusNode,
    );
    textPane = TextPane(
      focusNode: textPaneFocusNode,
    );
    timelinePane = TimelinePane(
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

    //loadText();
  }

  void loadText() async {
    String filePath = 'assets/ウェルカムティーフレンド.txt';
    String rawText = await rootBundle.loadString(filePath);
    timingService.initLyric(rawText);
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
      videoPaneFocusNode: videoPaneFocusNode,
      textPaneFocusNode: textPaneFocusNode,
      timelinePaneFocusNode: timelinePaneFocusNode,
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
