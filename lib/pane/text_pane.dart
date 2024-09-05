import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/sorted_list.dart';
import 'package:tuple/tuple.dart';

final textPaneMasterProvider = ChangeNotifierProvider((ref) {
  final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
  final TimingService timingService = ref.read(timingMasterProvider);
  return TextPaneProvider(musicPlayerProvider: musicPlayerService, timingService: timingService);
});

class TextPaneProvider with ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;
  final TimingService timingService;

  List<String> lyricAppearance = [];

  SnippetID cursorLinePosition = SnippetID(0);
  int cursorCharPosition = 0;
  int cursorCharPositionRestore = 0;
  Option cursorPositionOption = Option.former;

  List<SnippetID> highlightingSnippetsIDs = [];
  List<List<int>> timingPointsForEachLine = [];
  static const String timingPointChar = '|';

  TextPaneProvider({
    required this.musicPlayerProvider,
    required this.timingService,
  }) {
    musicPlayerProvider.addListener(() {
      updateCursorIfNeed();
    });
    timingService.addListener(() {
      Map<SnippetID, LyricSnippet> lyricSnippets = timingService.lyricSnippetList;
      lyricAppearance = List.filled(lyricSnippets.length, '');
      updateLyricAppearance();
    });
  }

  void updateCursorIfNeed() {
    if (highlightingSnippetsIDs.isNotEmpty && !highlightingSnippetsIDs.contains(cursorLinePosition)) {
      cursorLinePosition = highlightingSnippetsIDs[0];
      LyricSnippet nextSnippet = getSnippetWithID(cursorLinePosition);

      if (cursorCharPositionRestore != 0) {
        cursorCharPosition = cursorCharPositionRestore;
      }
      if (cursorCharPosition > nextSnippet.sentence.length) {
        cursorCharPositionRestore = cursorCharPosition;
        cursorCharPosition = nextSnippet.sentence.length;
      }

      //cursorBlinker.restartCursorTimer();
    }
  }

  LyricSnippet getSnippetWithID(SnippetID id) {
    final Map<SnippetID, LyricSnippet> lyricSnippetList = timingService.lyricSnippetList;
    return lyricSnippetList[id]!;
  }

  int countOccurrences(List<int> list, int number) {
    return list.where((element) => element == number).length;
  }

  void updateLyricAppearance() {
    final List<LyricSnippet> lyricSnippetList = timingService.lyricSnippetList.values.toList();
    timingPointsForEachLine = lyricSnippetList.map((snippet) => snippet.sentenceSegments.take(snippet.sentenceSegments.length - 1).map((sentenceSegmentMap) => sentenceSegmentMap.wordLength).fold<List<int>>([], (acc, pos) => acc..add((acc.isEmpty ? 0 : acc.last) + pos))).toList();
    for (int index = 0; index < timingPointsForEachLine.length; index++) {
      Map<int, String> timingPointsForEachLineMap = {};
      for (int i = 0; i < timingPointsForEachLine[index].length; i++) {
        int key = timingPointsForEachLine[index][i];
        if (timingPointsForEachLineMap.containsKey(key)) {
          timingPointsForEachLineMap[key] = timingPointsForEachLineMap[key]! + timingPointChar;
        } else {
          timingPointsForEachLineMap[key] = timingPointChar;
        }
      }
      lyricAppearance[index] = insertChars(lyricSnippetList[index].sentence, timingPointsForEachLineMap);
    }

    notifyListeners();
  }

  String insertChars(String originalString, Map<int, String> charPositions) {
    List<MapEntry<int, String>> sortedCharPositions = charPositions.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    String resultString = "";
    int previousPosition = 0;

    for (MapEntry<int, String> entry in sortedCharPositions) {
      resultString += originalString.substring(previousPosition, entry.key) + entry.value;
      previousPosition = entry.key;
    }
    resultString += originalString.substring(previousPosition);

    return resultString;
  }

  void moveUpCursor() {
    /*
    int highlightSnippetsIndex = highlightingSnippetsIDs.indexWhere((id) => id == cursorLinePosition);
    if (highlightSnippetsIndex > 0) {
      cursorPositionOption = Option.former;

      cursorLinePosition = highlightingSnippetsIDs[highlightSnippetsIndex - 1];
      LyricSnippet nextSnippet = getSnippetWithID(cursorLinePosition);

      if (cursorCharPositionRestore != 0) {
        cursorCharPosition = cursorCharPositionRestore;
      }
      if (cursorCharPosition > nextSnippet.sentence.length) {
        cursorCharPositionRestore = cursorCharPosition;
        cursorCharPosition = nextSnippet.sentence.length;
      }

      //cursorBlinker.restartCursorTimer();
      debugPrint("K key: LineCursor: ${cursorLinePosition}, CharCursor: ${cursorCharPosition}_${cursorPositionOption}");

      notifyListeners();
    }
    */
  }

  void moveDownCursor() {
    /*
    int highlightSnippetsIndex = highlightingSnippetsIDs.indexWhere((id) => id == cursorLinePosition);
    if (highlightSnippetsIndex < highlightingSnippetsIDs.length - 1) {
      cursorPositionOption = Option.former;

      cursorLinePosition = highlightingSnippetsIDs[highlightSnippetsIndex + 1];
      LyricSnippet nextSnippet = getSnippetWithID(cursorLinePosition);

      if (cursorCharPositionRestore != 0) {
        cursorCharPosition = cursorCharPositionRestore;
      }
      if (cursorCharPosition > nextSnippet.sentence.length) {
        cursorCharPositionRestore = cursorCharPosition;
        cursorCharPosition = nextSnippet.sentence.length;
      }

      //cursorBlinker.restartCursorTimer();
      debugPrint("J key: LineCursor: ${cursorLinePosition}, CharCursor: ${cursorCharPosition}_${cursorPositionOption}");

      notifyListeners();
    }
    */
  }

  void moveLeftCursor() {
    /*
    if (cursorCharPosition > 0) {
      cursorCharPositionRestore = 0;

      int snippetIndex = getSnippetIndexWithID(cursorLinePosition);
      if (cursorPositionOption == Option.former) {
        cursorCharPosition--;
        if (countOccurrences(timingPointsForEachLine[snippetIndex], cursorCharPosition) >= 2) {
          cursorPositionOption = Option.latter;
        }
      } else {
        cursorPositionOption = Option.former;
      }

      //cursorBlinker.restartCursorTimer();
      debugPrint("H key: LineCursor: ${cursorLinePosition}, CharCursor: ${cursorCharPosition}_${cursorPositionOption}");

      notifyListeners();
    }
    */
  }

  void moveRightCursor() {
    /*
    if (cursorCharPosition < getSnippetWithID(cursorLinePosition).sentence.length) {
      cursorCharPositionRestore = 0;

      int snippetIndex = getSnippetIndexWithID(cursorLinePosition);
      if (cursorPositionOption == Option.former) {
        if (countOccurrences(timingPointsForEachLine[snippetIndex], cursorCharPosition) >= 2) {
          cursorPositionOption = Option.latter;
        } else {
          cursorCharPosition++;
        }
      } else {
        cursorCharPosition++;
        cursorPositionOption = Option.former;
      }

      //cursorBlinker.restartCursorTimer();
      debugPrint("L key: LineCursor: ${cursorLinePosition}, CharCursor: ${cursorCharPosition}_${cursorPositionOption}");

      notifyListeners();
    }
    */
  }
}

class TextPane extends ConsumerStatefulWidget {
  final FocusNode focusNode;

  TextPane({required this.focusNode}) : super(key: Key('TextPane'));

  @override
  _TextPaneState createState() => _TextPaneState(focusNode);
}

class _TextPaneState extends ConsumerState<TextPane> {
  final FocusNode focusNode;

  static const String cursorChar = '\xa0';
  //static const String sectionChar = '\n\n';

  late CursorBlinker cursorBlinker;

  double lineHeight = 20;

  List<SnippetID> selectingSnippets = [];

  SortedMap<int, String> sentenceSegmentMap = SortedMap<int, String>();
  SortedMap<int, String> sectionPointMap = SortedMap<int, String>();

  int selectionBasePosition = 0;

  _TextPaneState(this.focusNode);

  @override
  void initState() {
    super.initState();

    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);
    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);

    musicPlayerService.addListener(() {
      setState(() {});
    });

    timingService.addListener(() {
      setState(() {});
    });

    textPaneProvider.addListener(() {
      setState(() {});
    });

    cursorBlinker = CursorBlinker(
        blinkIntervalInMillisec: 1000,
        onTick: () {
          setState(() {});
        });
  }

  LyricSnippet getSnippetWithID(SnippetID id) {
    final Map<SnippetID, LyricSnippet> lyricSnippetList = ref.read(timingMasterProvider).lyricSnippetList;
    return lyricSnippetList[id]!;
  }

  int countOccurrences(List<int> list, int number) {
    return list.where((element) => element == number).length;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        onTap: () {
          focusNode.requestFocus();
          debugPrint("The text pane is focused");
          setState(() {});
        },
        child: lyricListWidget(),
      ),
    );
  }

  Widget lyricListWidget() {
    final TimingService timingService = ref.read(timingMasterProvider);
    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    final List<String> lyricAppearance = textPaneProvider.lyricAppearance;

    final Map<SnippetID, LyricSnippet> currentSnippets = timingService.getCurrentSeekPositionSnippets();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: currentSnippets.length,
      itemBuilder: (context, index) {
        return Text(lyricAppearance[0]);
      },
    );
  }

  Widget highlightedLyricItem(String lyrics, SnippetID snippetID, int charIndex) {
    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    final Option cursorPositionOption = textPaneProvider.cursorPositionOption;
    final List<List<int>> timingPointsForEachLine = textPaneProvider.timingPointsForEachLine;

    int sentenceSegmentsBeforeCursor = 0;
    //int lineIndex = getSnippetIndexWithID(snippetID);
    int lineIndex = 0;
    List<int> currentLinesentenceSegment = timingPointsForEachLine[lineIndex];
    while (sentenceSegmentsBeforeCursor < currentLinesentenceSegment.length && currentLinesentenceSegment[sentenceSegmentsBeforeCursor] < charIndex) {
      sentenceSegmentsBeforeCursor++;
    }
    int cursorIndexsentenceSegments = currentLinesentenceSegment.indexOf(charIndex);

    charIndex = charIndex + sentenceSegmentsBeforeCursor;
    if (cursorIndexsentenceSegments >= 0) {
      if (cursorPositionOption == Option.latter) {
        charIndex++;
      }
      lyrics = replaceNthCharacter(lyrics, charIndex, cursorChar);
    } else {
      lyrics = insertCharacterAt(lyrics, charIndex, cursorChar);
    }

    String beforeN = lyrics.substring(0, charIndex);
    String charAtN = lyrics[charIndex].toString();
    String afterN = lyrics.substring(charIndex + 1);

    Color cursorColor = cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: beforeN, style: TextStyle(fontSize: 14, color: Colors.black)),
          TextSpan(text: charAtN, style: TextStyle(fontSize: 14, backgroundColor: cursorColor)),
          TextSpan(text: afterN, style: TextStyle(fontSize: 14, color: Colors.black)),
        ],
      ),
    );
  }

  Widget highlightedLyricItemSelectionMode(String lyrics, int lineIndex, int charIndex) {
    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    final int cursorCharPosition = textPaneProvider.cursorCharPosition;

    String beforeSelect = lyrics.substring(0, selectionBasePosition);
    String selecting = lyrics.substring(selectionBasePosition, cursorCharPosition);
    String afterSelect = lyrics.substring(cursorCharPosition);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: beforeSelect,
            style: const TextStyle(fontSize: 20, color: Colors.black),
          ),
          TextSpan(
            text: selecting,
            style: const TextStyle(fontSize: 20, color: Colors.black, backgroundColor: Colors.blue),
          ),
          TextSpan(
            text: afterSelect,
            style: const TextStyle(fontSize: 20, color: Colors.black),
          ),
        ],
      ),
    );
  }

  String replaceNthCharacter(String originalString, int index, String newChar) {
    return originalString.substring(0, index) + newChar + originalString.substring(index + 1);
  }

  String insertCharacterAt(String originalString, int index, String insertingChar) {
    return originalString.substring(0, index) + insertingChar + originalString.substring(index);
  }

  Map<int, String> AddChar(Map<int, String> mapToBeAdded, Map<int, String> mapToAdd) {
    Map<int, String> charPositions = {...mapToBeAdded};
    for (var entry in mapToAdd.entries) {
      charPositions[entry.key] = entry.value;
    }
    return charPositions;
  }
}
