import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_data/reading/reading_map.dart';
import 'package:lyric_editor/sentence/id/lyric_snippet_id.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/reading_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_controller.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/reading_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/word_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/sentence_selection_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/text_pane_provider.dart';
import 'package:lyric_editor/pane/video_pane/video_pane_provider.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timeline.dart';
import 'package:lyric_editor/pane/timeline_pane/timeline_pane.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/dialog/text_field_dialog.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';

final keyboardShortcutsMasterProvider = ChangeNotifierProvider((ref) => KeyboardShortcutsNotifier());

class KeyboardShortcutsNotifier with ChangeNotifier {
  bool _enable = true;

  bool get enable => _enable;

  void setEnable(bool value) {
    _enable = value;
    notifyListeners();
  }

  KeyboardShortcutsNotifier();
}

class KeyboardShortcuts extends ConsumerStatefulWidget {
  final Widget child;
  final FocusNode videoPaneFocusNode;
  final FocusNode textPaneFocusNode;
  final FocusNode timelinePaneFocusNode;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    required this.videoPaneFocusNode,
    required this.textPaneFocusNode,
    required this.timelinePaneFocusNode,
  });

  @override
  _KeyboardShortcutsState createState() => _KeyboardShortcutsState(child: child, videoPaneFocusNode: videoPaneFocusNode, textPaneFocusNode: textPaneFocusNode, timelinePaneFocusNode: timelinePaneFocusNode);
}

class _KeyboardShortcutsState extends ConsumerState<KeyboardShortcuts> {
  final Widget child;
  final FocusNode videoPaneFocusNode;
  final FocusNode textPaneFocusNode;
  final FocusNode timelinePaneFocusNode;

  late final MusicPlayerService musicPlayerProvider = ref.watch(musicPlayerMasterProvider.notifier);
  late final TimingService timingService = ref.watch(timingMasterProvider.notifier);
  late final TextPaneProvider textPaneProvider = ref.watch(textPaneMasterProvider.notifier);
  late final TimelinePaneProvider timelinePaneProvider = ref.watch(timelinePaneMasterProvider.notifier);
  late final VideoPaneProvider videoPaneProvider = ref.watch(videoPaneMasterProvider.notifier);

  bool enable = true;

  _KeyboardShortcutsState({
    required this.child,
    required this.videoPaneFocusNode,
    required this.textPaneFocusNode,
    required this.timelinePaneFocusNode,
  });

  @override
  void initState() {
    super.initState();
  }

  Map<LogicalKeySet, Intent> get shortcuts => {
        LogicalKeySet(LogicalKeyboardKey.space): PlayPauseIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyN): RewindIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyM): ForwardIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS): AddSnippetIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyA): EnterSegmentSelectionIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): DeleteSnippetIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA): DeleteAnnotationIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyC): SnippetStartMoveIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyV): textPaneProvider.textPaneCursorController.textPaneListCursor is SegmentSelectionListCursor ? SegmentRangeSelectIntent() : SnippetEndMoveIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): SpeedDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): SpeedUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): VolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): VolumeDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyI): TimingPointAddIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyO): TimingPointDeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyZ): SnippetDivideIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyX): SnippetConcatenateIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyU): UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyH): TextPaneCursorMoveLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyJ): TextPaneCursorMoveDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyK): TextPaneCursorMoveUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyL): TextPaneCursorMoveRightIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyG): TimelineCursorMoveLeft(),
        LogicalKeySet(LogicalKeyboardKey.keyF): TimelineCursorMoveDown(),
        LogicalKeySet(LogicalKeyboardKey.keyD): TimelineCursorMoveUp(),
        LogicalKeySet(LogicalKeyboardKey.keyS): TimelineCursorMoveRight(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyK): TimelineZoomInIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyJ): TimelineZoomOutIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyE): AddSectionIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyR): DeleteSectionIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyD): DisplayModeSwitchIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): AddAnnotationIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): CancelIntent(),
      };

  Map<Type, Action<Intent>> get actions => {
        PlayPauseIntent: CallbackAction<PlayPauseIntent>(
          onInvoke: (PlayPauseIntent intent) => () {
            musicPlayerProvider.playPause();
          }(),
        ),
        RewindIntent: CallbackAction<RewindIntent>(
          onInvoke: (RewindIntent intent) => () {
            musicPlayerProvider.rewind(1000);
          }(),
        ),
        ForwardIntent: CallbackAction<ForwardIntent>(
          onInvoke: (ForwardIntent intent) => () {
            musicPlayerProvider.forward(1000);
          }(),
        ),
        AddSnippetIntent: CallbackAction<AddSnippetIntent>(
          onInvoke: (AddSnippetIntent intent) => () {
            Timeline timing = Timeline(
              startTime: musicPlayerProvider.seekPosition,
              wordList: WordList([
                Word("default sentence", Duration(milliseconds: 3000)),
              ]),
            );
            Sentence lyricSnippet = Sentence(
              vocalistID: timelinePaneProvider.selectingVocalist[0],
              timeline: timing,
              readingMap: ReadingMap.empty,
            );
            timingService.addLyricSnippet(lyricSnippet);
          }(),
        ),
        DeleteSnippetIntent: CallbackAction<DeleteSnippetIntent>(
          onInvoke: (DeleteSnippetIntent intent) => () {
            timingService.removeLyricSnippet(timelinePaneProvider.selectingSentences[0]);
          }(),
        ),
        EnterSegmentSelectionIntent: CallbackAction<EnterSegmentSelectionIntent>(
          onInvoke: (EnterSegmentSelectionIntent intent) => () {
            if (textPaneProvider.textPaneCursorController.textPaneListCursor is! SentenceSelectionListCursor) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You cannot add an annotation to an annotation."),
                ),
              );
            }
            textPaneProvider.enterSegmentSelectionMode();
            setState(() {});
          }(),
        ),
        SegmentRangeSelectIntent: CallbackAction<SegmentRangeSelectIntent>(
          onInvoke: (SegmentRangeSelectIntent intent) => () {
            textPaneProvider.switchToRangeSelection();
            setState(() {});
          }(),
        ),
        AddAnnotationIntent: CallbackAction<AddAnnotationIntent>(
          onInvoke: (AddAnnotationIntent intent) => () async {
            TextPaneCursorController cursorController = textPaneProvider.textPaneCursorController;
            assert(cursorController.textPaneListCursor is SegmentSelectionListCursor, "An unintended error occurred when adding an annotation. The cursor type must be segment type.");

            SegmentSelectionListCursor listCursor = cursorController.textPaneListCursor as SegmentSelectionListCursor;
            LyricSnippetID lyricSnippetID = listCursor.lyricSnippetID;

            SegmentSelectionCursor cursor = listCursor.textPaneCursor as SegmentSelectionCursor;
            PhrasePosition segmentRange = cursor.segmentRange;

            String annotationString = (await displayTextFieldDialog(context, [""]))[0];
            if (annotationString != "") {
              timingService.addAnnotation(lyricSnippetID, segmentRange, annotationString);
            }
            textPaneProvider.exitSegmentSelectionMode();
          }(),
        ),
        DeleteAnnotationIntent: CallbackAction<DeleteAnnotationIntent>(
          onInvoke: (DeleteAnnotationIntent intent) => () {
            TextPaneListCursor listCursor = textPaneProvider.textPaneCursorController.textPaneListCursor;
            LyricSnippetID lyricSnippetID = listCursor.lyricSnippetID;
            if (listCursor is! ReadingSelectionListCursor) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cannot determine which annotation should be deleted."),
                ),
              );
            }

            ReadingSelectionCursor cursor = listCursor.textPaneCursor as ReadingSelectionCursor;
            PhrasePosition segmentRange = cursor.phrase;
            timingService.removeAnnotation(lyricSnippetID, segmentRange);
          }(),
        ),
        SnippetStartMoveIntent: CallbackAction<SnippetStartMoveIntent>(
          onInvoke: (SnippetStartMoveIntent intent) => () {
            for (var id in timelinePaneProvider.selectingSentences) {
              timingService.manipulateSnippet(id, SentenceEdge.start, false);
            }
          }(),
        ),
        SnippetEndMoveIntent: CallbackAction<SnippetEndMoveIntent>(
          onInvoke: (SnippetEndMoveIntent intent) => () {
            for (var id in timelinePaneProvider.selectingSentences) {
              timingService.manipulateSnippet(id, SentenceEdge.end, false);
            }
          }(),
        ),
        VolumeUpIntent: CallbackAction<VolumeUpIntent>(
          onInvoke: (VolumeUpIntent intent) => () {
            musicPlayerProvider.volumeUp(0.1);
          }(),
        ),
        VolumeDownIntent: CallbackAction<VolumeDownIntent>(
          onInvoke: (VolumeDownIntent intent) => () {
            musicPlayerProvider.volumeDown(0.1);
          }(),
        ),
        SpeedUpIntent: CallbackAction<SpeedUpIntent>(
          onInvoke: (SpeedUpIntent intent) => () {
            musicPlayerProvider.speedUp(0.1);
          }(),
        ),
        SpeedDownIntent: CallbackAction<SpeedDownIntent>(
          onInvoke: (SpeedDownIntent intent) => () {
            musicPlayerProvider.speedDown(0.1);
          }(),
        ),
        UndoIntent: CallbackAction<UndoIntent>(
          onInvoke: (UndoIntent intent) => () {
            timingService.undo();
          }(),
        ),
        TextPaneCursorMoveLeftIntent: CallbackAction<TextPaneCursorMoveLeftIntent>(
          onInvoke: (TextPaneCursorMoveLeftIntent intent) => () {
            textPaneProvider.moveLeftCursor();
          }(),
        ),
        TextPaneCursorMoveDownIntent: CallbackAction<TextPaneCursorMoveDownIntent>(
          onInvoke: (TextPaneCursorMoveDownIntent intent) => () {
            textPaneProvider.moveDownCursor();
          }(),
        ),
        TextPaneCursorMoveUpIntent: CallbackAction<TextPaneCursorMoveUpIntent>(
          onInvoke: (TextPaneCursorMoveUpIntent intent) => () {
            textPaneProvider.moveUpCursor();
          }(),
        ),
        TextPaneCursorMoveRightIntent: CallbackAction<TextPaneCursorMoveRightIntent>(
          onInvoke: (TextPaneCursorMoveRightIntent intent) => () {
            textPaneProvider.moveRightCursor();
          }(),
        ),
        TimelineZoomInIntent: CallbackAction<TimelineZoomInIntent>(
          onInvoke: (TimelineZoomInIntent intent) => () {
            timelinePaneProvider.zoomIn();
          }(),
        ),
        TimelineZoomOutIntent: CallbackAction<TimelineZoomOutIntent>(
          onInvoke: (TimelineZoomOutIntent intent) => () {
            timelinePaneProvider.zoomOut();
          }(),
        ),
        AddSectionIntent: CallbackAction<AddSectionIntent>(
          onInvoke: (AddSectionIntent intent) => () {
            SeekPosition seekPosition = musicPlayerProvider.seekPosition;
            timingService.addSection(seekPosition);
          }(),
        ),
        DeleteSectionIntent: CallbackAction<DeleteSectionIntent>(
          onInvoke: (DeleteSectionIntent intent) => () {
            SeekPosition seekPosition = musicPlayerProvider.seekPosition;
            timingService.removeSection(seekPosition);
          }(),
        ),
        TimingPointAddIntent: CallbackAction<TimingPointAddIntent>(
          onInvoke: (TimingPointAddIntent intent) => () {
            SeekPosition seekPosition = musicPlayerProvider.seekPosition;
            TextPaneListCursor listCursor = textPaneProvider.textPaneCursorController.textPaneListCursor;
            if (listCursor is SentenceSelectionListCursor) {
              SentenceSelectionCursor cursor = listCursor.textPaneCursor as SentenceSelectionCursor;
              timingService.addTimingPoint(
                listCursor.lyricSnippetID,
                cursor.insertionPosition,
                seekPosition,
              );
            }
            if (listCursor is ReadingSelectionListCursor) {
              ReadingSelectionCursor cursor = listCursor.textPaneCursor as ReadingSelectionCursor;
              timingService.addAnnotationTimingPoint(
                listCursor.lyricSnippetID,
                cursor.phrase,
                cursor.insertionPosition,
                seekPosition,
              );
            }
          }(),
        ),
        TimingPointDeleteIntent: CallbackAction<TimingPointDeleteIntent>(
          onInvoke: (TimingPointDeleteIntent intent) => () {
            TextPaneListCursor listCursor = textPaneProvider.textPaneCursorController.textPaneListCursor;
            LyricSnippetID lyricSnippetID = listCursor.lyricSnippetID;
            if (listCursor is SentenceSelectionListCursor) {
              SentenceSelectionCursor cursor = listCursor.textPaneCursor as SentenceSelectionCursor;
              timingService.removeTimingPoint(
                lyricSnippetID,
                cursor.insertionPosition,
                cursor.option,
              );
            }
            if (listCursor is ReadingSelectionListCursor) {
              ReadingSelectionCursor cursor = listCursor.textPaneCursor as ReadingSelectionCursor;
              timingService.removeAnnotationTimingPoint(
                lyricSnippetID,
                cursor.phrase,
                cursor.insertionPosition,
                cursor.option,
              );
            }
          }(),
        ),
        SnippetDivideIntent: CallbackAction<SnippetDivideIntent>(
          onInvoke: (SnippetDivideIntent intent) => () {
            TextPaneListCursor listCursor = textPaneProvider.textPaneCursorController.textPaneListCursor;
            if (listCursor is SentenceSelectionListCursor) {
              SentenceSelectionCursor cursor = listCursor.textPaneCursor as SentenceSelectionCursor;
              timingService.divideSnippet(timelinePaneProvider.selectingSentences[0], cursor.insertionPosition, musicPlayerProvider.seekPosition);
            }
          }(),
        ),
        SnippetConcatenateIntent: CallbackAction<SnippetConcatenateIntent>(
          onInvoke: (SnippetConcatenateIntent intent) => () {
            final List<LyricSnippetID> selectingSnippets = timelinePaneProvider.selectingSentences;
            if (selectingSnippets.length >= 2) {
              timingService.concatenateSnippets(selectingSnippets[0], selectingSnippets[1]);
            }
          }(),
        ),
        DisplayModeSwitchIntent: CallbackAction<DisplayModeSwitchIntent>(
          onInvoke: (DisplayModeSwitchIntent intent) => () {
            videoPaneProvider.switchDisplayMode();
          }(),
        ),
        TimelineCursorMoveLeft: CallbackAction<TimelineCursorMoveLeft>(
          onInvoke: (TimelineCursorMoveLeft intent) => () {
            timelinePaneProvider.moveLeftCursor();
          }(),
        ),
        TimelineCursorMoveDown: CallbackAction<TimelineCursorMoveDown>(
          onInvoke: (TimelineCursorMoveDown intent) => () {
            timelinePaneProvider.moveDownCursor();
          }(),
        ),
        TimelineCursorMoveUp: CallbackAction<TimelineCursorMoveUp>(
          onInvoke: (TimelineCursorMoveUp intent) => () {
            timelinePaneProvider.moveUpCursor();
          }(),
        ),
        TimelineCursorMoveRight: CallbackAction<TimelineCursorMoveRight>(
          onInvoke: (TimelineCursorMoveRight intent) => () {
            timelinePaneProvider.moveRightCursor();
          }(),
        ),
        CancelIntent: CallbackAction<CancelIntent>(
          onInvoke: (CancelIntent intent) => () {
            if (textPaneProvider.textPaneCursorController.textPaneListCursor is SegmentSelectionCursor) {
              textPaneProvider.exitSegmentSelectionMode();
            }
          }(),
        ),
      };

  @override
  Widget build(BuildContext context) {
    if (enable) {
      return Shortcuts(
        shortcuts: shortcuts,
        child: Actions(
          actions: actions,
          child: child,
        ),
      );
    } else {
      return Shortcuts(
        shortcuts: const <LogicalKeySet, Intent>{},
        child: Actions(
          actions: const <Type, Action<Intent>>{},
          child: child,
        ),
      );
    }
  }
}

class PlayPauseIntent extends Intent {}

class ForwardIntent extends Intent {}

class RewindIntent extends Intent {}

class AddSnippetIntent extends Intent {}

class DeleteSnippetIntent extends Intent {}

class AddAnnotationIntent extends Intent {}

class DeleteAnnotationIntent extends Intent {}

class SnippetStartMoveIntent extends Intent {}

class SnippetEndMoveIntent extends Intent {}

class VolumeUpIntent extends Intent {}

class VolumeDownIntent extends Intent {}

class SpeedUpIntent extends Intent {}

class SpeedDownIntent extends Intent {}

class UndoIntent extends Intent {}

class TextPaneCursorMoveDownIntent extends Intent {}

class TextPaneCursorMoveUpIntent extends Intent {}

class TextPaneCursorMoveLeftIntent extends Intent {}

class TextPaneCursorMoveRightIntent extends Intent {}

class TimelineZoomInIntent extends Intent {}

class TimelineZoomOutIntent extends Intent {}

class EnterSegmentSelectionIntent extends Intent {}

class SegmentRangeSelectIntent extends Intent {}

class AddSectionIntent extends Intent {}

class DeleteSectionIntent extends Intent {}

class TimingPointAddIntent extends Intent {}

class TimingPointDeleteIntent extends Intent {}

class SnippetDivideIntent extends Intent {}

class SnippetConcatenateIntent extends Intent {}

class DisplayModeSwitchIntent extends Intent {}

class TimelineCursorMoveLeft extends Intent {}

class TimelineCursorMoveDown extends Intent {}

class TimelineCursorMoveUp extends Intent {}

class TimelineCursorMoveRight extends Intent {}

class CancelIntent extends Intent {}
