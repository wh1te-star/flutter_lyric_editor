import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby_map.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/ruby_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_controller.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/ruby_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/word_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/base_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/text_pane_provider.dart';
import 'package:lyric_editor/pane/video_pane/video_pane_provider.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timetable.dart';
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
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS): AddSentenceIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyA): EnterWordModeIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): DeleteSentenceIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA): DeleteRubyIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyC): SentenceStartMoveIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyV): textPaneProvider.textPaneCursorController.textPaneListCursor is WordListCursor ? SwitchExpandModeIntent() : SentenceEndMoveIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): SpeedDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): SpeedUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): VolumeUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): VolumeDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyI): TimingPointAddIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyO): TimingPointDeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyZ): SentenceDivideIntent(),
        LogicalKeySet(LogicalKeyboardKey.keyX): SentenceConcatenateIntent(),
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
        LogicalKeySet(LogicalKeyboardKey.enter): AddRubyIntent(),
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
        AddSentenceIntent: CallbackAction<AddSentenceIntent>(
          onInvoke: (AddSentenceIntent intent) => () {
            Timing timing = Timing(
              startTimestamp: musicPlayerProvider.seekPosition,
              sentenceSegmentList: SentenceSegmentList([
                SentenceSegment("default sentence", Duration(milliseconds: 3000)),
              ]),
            );
            Sentence sentence = Sentence(
              vocalistID: timelinePaneProvider.selectingVocalist[0],
              timing: timing,
              rubyMap: RubyMap.empty,
            );
            timingService.addSentence(sentence);
          }(),
        ),
        DeleteSentenceIntent: CallbackAction<DeleteSentenceIntent>(
          onInvoke: (DeleteSentenceIntent intent) => () {
            timingService.removeSentence(timelinePaneProvider.selectingSentence[0]);
          }(),
        ),
        EnterWordModeIntent: CallbackAction<EnterWordModeIntent>(
          onInvoke: (EnterWordModeIntent intent) => () {
            if (textPaneProvider.textPaneCursorController.textPaneListCursor is! BaseListCursor) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You cannot add an ruby to an ruby."),
                ),
              );
            }
            textPaneProvider.enterWordMode();
            setState(() {});
          }(),
        ),
        SwitchExpandModeIntent: CallbackAction<SwitchExpandModeIntent>(
          onInvoke: (SwitchExpandModeIntent intent) => () {
            textPaneProvider.switchToExpandMode();
            setState(() {});
          }(),
        ),
        AddRubyIntent: CallbackAction<AddRubyIntent>(
          onInvoke: (AddRubyIntent intent) => () async {
            TextPaneCursorController cursorController = textPaneProvider.textPaneCursorController;
            assert(cursorController.textPaneListCursor is WordListCursor, "An unintended error occurred when adding a ruby. The cursor type must be segment type.");

            WordListCursor listCursor = cursorController.textPaneListCursor as WordListCursor;
            SentenceID sentenceID = listCursor.sentenceID;

            WordCursor cursor = listCursor.textPaneCursor as WordCursor;
            PhrasePosition phrasePosition = cursor.phrasePosition;

            String rubyString = (await displayTextFieldDialog(context, [""]))[0];
            if (rubyString != "") {
              timingService.addRuby(sentenceID, phrasePosition, rubyString);
            }
            textPaneProvider.exitWordMode();
          }(),
        ),
        DeleteRubyIntent: CallbackAction<DeleteRubyIntent>(
          onInvoke: (DeleteRubyIntent intent) => () {
            TextPaneListCursor listCursor = textPaneProvider.textPaneCursorController.textPaneListCursor;
            SentenceID sentenceID = listCursor.sentenceID;
            if (listCursor is! RubyListCursor) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Cannot determine which ruby should be deleted."),
                ),
              );
            }

            RubyCursor cursor = listCursor.textPaneCursor as RubyCursor;
            PhrasePosition phrasePosition = cursor.phrasePosition;
            timingService.removeRuby(sentenceID, phrasePosition);
          }(),
        ),
        SentenceStartMoveIntent: CallbackAction<SentenceStartMoveIntent>(
          onInvoke: (SentenceStartMoveIntent intent) => () {
            for (var id in timelinePaneProvider.selectingSentence) {
              timingService.manipulateSentence(id, SentenceEdge.start, false);
            }
          }(),
        ),
        SentenceEndMoveIntent: CallbackAction<SentenceEndMoveIntent>(
          onInvoke: (SentenceEndMoveIntent intent) => () {
            for (var id in timelinePaneProvider.selectingSentence) {
              timingService.manipulateSentence(id, SentenceEdge.end, false);
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
            if (listCursor is BaseListCursor) {
              BaseCursor cursor = listCursor.textPaneCursor as BaseCursor;
              timingService.addTimingPoint(
                listCursor.sentenceID,
                cursor.insertionPosition,
                seekPosition,
              );
            }
            if (listCursor is RubyListCursor) {
              RubyCursor cursor = listCursor.textPaneCursor as RubyCursor;
              timingService.addRubyTimingPoint(
                listCursor.sentenceID,
                cursor.phrasePosition,
                cursor.insertionPosition,
                seekPosition,
              );
            }
          }(),
        ),
        TimingPointDeleteIntent: CallbackAction<TimingPointDeleteIntent>(
          onInvoke: (TimingPointDeleteIntent intent) => () {
            TextPaneListCursor listCursor = textPaneProvider.textPaneCursorController.textPaneListCursor;
            SentenceID sentenceID = listCursor.sentenceID;
            if (listCursor is BaseListCursor) {
              BaseCursor cursor = listCursor.textPaneCursor as BaseCursor;
              timingService.removeTimingPoint(
                sentenceID,
                cursor.insertionPosition,
                cursor.option,
              );
            }
            if (listCursor is RubyListCursor) {
              RubyCursor cursor = listCursor.textPaneCursor as RubyCursor;
              timingService.removeRubyTimingPoint(
                sentenceID,
                cursor.phrasePosition,
                cursor.insertionPosition,
                cursor.option,
              );
            }
          }(),
        ),
        SentenceDivideIntent: CallbackAction<SentenceDivideIntent>(
          onInvoke: (SentenceDivideIntent intent) => () {
            TextPaneListCursor listCursor = textPaneProvider.textPaneCursorController.textPaneListCursor;
            if (listCursor is BaseListCursor) {
              BaseCursor cursor = listCursor.textPaneCursor as BaseCursor;
              timingService.divideSentence(timelinePaneProvider.selectingSentence[0], cursor.insertionPosition, musicPlayerProvider.seekPosition);
            }
          }(),
        ),
        SentenceConcatenateIntent: CallbackAction<SentenceConcatenateIntent>(
          onInvoke: (SentenceConcatenateIntent intent) => () {
            final List<SentenceID> selectingSentences = timelinePaneProvider.selectingSentence;
            if (selectingSentences.length >= 2) {
              timingService.concatenateSentences(selectingSentences[0], selectingSentences[1]);
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
            if (textPaneProvider.textPaneCursorController.textPaneListCursor is WordCursor) {
              textPaneProvider.exitWordMode();
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

class AddSentenceIntent extends Intent {}

class DeleteSentenceIntent extends Intent {}

class AddRubyIntent extends Intent {}

class DeleteRubyIntent extends Intent {}

class SentenceStartMoveIntent extends Intent {}

class SentenceEndMoveIntent extends Intent {}

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

class EnterWordModeIntent extends Intent {}

class SwitchExpandModeIntent extends Intent {}

class AddSectionIntent extends Intent {}

class DeleteSectionIntent extends Intent {}

class TimingPointAddIntent extends Intent {}

class TimingPointDeleteIntent extends Intent {}

class SentenceDivideIntent extends Intent {}

class SentenceConcatenateIntent extends Intent {}

class DisplayModeSwitchIntent extends Intent {}

class TimelineCursorMoveLeft extends Intent {}

class TimelineCursorMoveDown extends Intent {}

class TimelineCursorMoveUp extends Intent {}

class TimelineCursorMoveRight extends Intent {}

class CancelIntent extends Intent {}
