import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/word_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/base_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TextPaneCursorController {
  final SentenceMap sentenceMap;
  final SentenceID sentenceID;
  final TextPaneListCursor textPaneListCursor;
  final SeekPosition seekPosition;
  final CursorBlinker cursorBlinker;

  TextPaneCursorController({
    required this.sentenceMap,
    required this.sentenceID,
    required this.textPaneListCursor,
    required this.seekPosition,
    required this.cursorBlinker,
  });

  TextPaneCursorController._privateConstructor(
    this.sentenceMap,
    this.sentenceID,
    this.textPaneListCursor,
    this.seekPosition,
    this.cursorBlinker,
  );
  static final TextPaneCursorController _empty = TextPaneCursorController._privateConstructor(
    SentenceMap.empty,
    SentenceID.empty,
    BaseListCursor.empty,
    SeekPosition.empty,
    CursorBlinker.empty,
  );
  static TextPaneCursorController get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TextPaneCursorController moveUpCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneListCursor nextCursor = textPaneListCursor.moveUpCursor();
    return copyWith(textPaneListCursor: nextCursor);
  }

  TextPaneCursorController moveDownCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneListCursor nextCursor = textPaneListCursor.moveDownCursor();
    return copyWith(textPaneListCursor: nextCursor);
  }

  TextPaneCursorController moveLeftCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneListCursor nextCursor = textPaneListCursor.moveLeftCursor();
    return copyWith(textPaneListCursor: nextCursor);
  }

  TextPaneCursorController moveRightCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneListCursor nextCursor = textPaneListCursor.moveRightCursor();
    return copyWith(textPaneListCursor: nextCursor);
  }

  TextPaneCursorController enterWordMode() {
    assert(textPaneListCursor is BaseListCursor, "This is an unexpected call. The cursor type must be BaseCursor, but is ${textPaneListCursor.runtimeType}");
    TextPaneListCursor cursor = (textPaneListCursor as BaseListCursor).enterWordMode();
    return copyWith(textPaneListCursor: cursor);
  }

  TextPaneCursorController exitWordMode() {
    assert(textPaneListCursor is WordListCursor, "This is an unexpected call. The cursor type must be WordCursor, but is ${textPaneListCursor.runtimeType}");
    TextPaneListCursor cursor = (textPaneListCursor as WordListCursor).exitWordMode();
    return copyWith(textPaneListCursor: cursor);
  }

  TextPaneCursorController switchToExpandMode() {
    assert(textPaneListCursor is WordListCursor, "This is an unexpected call. The cursor type must be WordCursor, but is ${textPaneListCursor.runtimeType}");
    TextPaneListCursor cursor = (textPaneListCursor as WordListCursor).switchToExpandMode();
    return copyWith(textPaneListCursor: cursor);
  }

  TextPaneCursorController updateCursor(
    SentenceMap sentenceMap,
    SeekPosition seekPosition,
  ) {
    TextPaneListCursor nextCursor = textPaneListCursor.updateCursor(sentenceMap, sentenceID, seekPosition);
    return copyWith(textPaneListCursor: nextCursor);
  }

  TextPaneCursorController copyWith({
    SentenceMap? sentenceMap,
    SentenceID? sentenceID,
    TextPaneListCursor? textPaneListCursor,
    SeekPosition? seekPosition,
    CursorBlinker? cursorBlinker,
  }) {
    return TextPaneCursorController(
      sentenceMap: sentenceMap ?? this.sentenceMap,
      sentenceID: sentenceID ?? this.sentenceID,
      textPaneListCursor: textPaneListCursor ?? this.textPaneListCursor,
      seekPosition: seekPosition ?? this.seekPosition,
      cursorBlinker: cursorBlinker ?? this.cursorBlinker,
    );
  }

  @override
  String toString() {
    return 'TextPaneCursorController()';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TextPaneCursorController otherWords = other as TextPaneCursorController;
    if (sentenceMap != otherWords.sentenceMap) return false;
    if (sentenceID != otherWords.sentenceID) return false;
    if (textPaneListCursor != otherWords.textPaneListCursor) return false;
    if (seekPosition != otherWords.seekPosition) return false;
    if (cursorBlinker != otherWords.cursorBlinker) return false;
    return true;
  }

  @override
  int get hashCode => sentenceMap.hashCode ^ sentenceID.hashCode ^ textPaneListCursor.hashCode ^ seekPosition.hashCode ^ cursorBlinker.hashCode;
}
