import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
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
  int maxLanes = 0;

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
      maxLanes = getMaxTracks(lyricSnippets.values.toList());
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

  int getMaxTracks(List<LyricSnippet> lyricSnippetList) {
    int maxOverlap = 0;
    int currentOverlap = 1;
    int currentEndTime = lyricSnippetList[0].endTimestamp;

    for (int i = 1; i < lyricSnippetList.length; ++i) {
      int start = lyricSnippetList[i].startTimestamp;
      int end = lyricSnippetList[i].endTimestamp;
      if (start <= currentEndTime) {
        currentOverlap++;
      } else {
        currentOverlap = 1;
        currentEndTime = end;
      }
      if (currentOverlap > maxOverlap) {
        maxOverlap = currentOverlap;
      }

      if (currentOverlap > maxLanes) {
        maxLanes = currentOverlap;
      }
    }
    return maxLanes;
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

  Tuple3<List<SnippetID>, List<SnippetID>, List<SnippetID>> getSnippetIDsAtCurrentSeekPosition() {
    int seekPosition = ref.read(musicPlayerMasterProvider).seekPosition;
    final Map<SnippetID, LyricSnippet> lyricSnippetList = ref.read(timingMasterProvider).lyricSnippetList;

    List<SnippetID> beforeSnippetIndexes = [];
    List<SnippetID> currentSnippetIndexes = [];
    List<SnippetID> afterSnippetIndexes = [];
    lyricSnippetList.forEach((SnippetID id, LyricSnippet snippet) {
      int start = snippet.startTimestamp;
      int end = snippet.endTimestamp;
      if (seekPosition < start) {
        beforeSnippetIndexes.add(id);
      } else if (seekPosition < end) {
        currentSnippetIndexes.add(id);
      } else {
        afterSnippetIndexes.add(id);
      }
    });
    return Tuple3(beforeSnippetIndexes, currentSnippetIndexes, afterSnippetIndexes);
  }

  List<int> getIndexFromIDs(List<SnippetID> lyricSnippetIDs) {
    final Map<SnippetID, LyricSnippet> lyricSnippetList = ref.read(timingMasterProvider).lyricSnippetList;
    List<int> indexes = [];
    for (var entry in lyricSnippetList.entries) {
      if (lyricSnippetIDs.contains(entry.key)) {
        indexes.add(lyricSnippetList.keys.toList().indexOf(entry.key));
      }
    }
    return indexes;
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
    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    final List<String> lyricAppearance = textPaneProvider.lyricAppearance;
    final int maxLanes = textPaneProvider.maxLanes;
    final SnippetID cursorLinePosition = textPaneProvider.cursorLinePosition;
    final int cursorCharPosition = textPaneProvider.cursorCharPosition;

    final indexesTuple = getSnippetIDsAtCurrentSeekPosition();
    late List<SnippetID> beforeSnippetIDs;
    late List<SnippetID> currentSnippetIDs;
    late List<SnippetID> afterSnippetIDs;
    if (selectingSnippets.isEmpty) {
      beforeSnippetIDs = indexesTuple.item1;
      currentSnippetIDs = indexesTuple.item2;
      afterSnippetIDs = indexesTuple.item3;
    } else {
      beforeSnippetIDs = indexesTuple.item1 + indexesTuple.item2;
      currentSnippetIDs = selectingSnippets;
      afterSnippetIDs = indexesTuple.item3;
    }
    textPaneProvider.highlightingSnippetsIDs = currentSnippetIDs;

    late double height;
    if (selectingSnippets.length < maxLanes) {
      height = lineHeight * maxLanes;
    } else {
      height = lineHeight * selectingSnippets.length;
    }
    return Column(
      children: [
        /*
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: afterSnippetIDs.length,
            itemBuilder: (context, index) {
              int lyricSnippetIndex = getSnippetIndexWithID(afterSnippetIDs[index]);
              return Text(lyricAppearance[lyricSnippetIndex]);
            },
          ),
        ),
        */
        Center(
          child: Container(
            height: height,
            color: Colors.yellowAccent,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currentSnippetIDs.length,
              itemBuilder: (context, index) {
                //int lyricSnippetIndex = getSnippetIndexWithID(currentSnippetIDs[index]);
                if (currentSnippetIDs[index] == cursorLinePosition) {
                  return highlightedLyricItem(lyricAppearance[0], cursorLinePosition, cursorCharPosition);
                } else {
                  return Text(lyricAppearance[0]);
                }
              },
            ),
          ),
        ),
        /*
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: beforeSnippetIDs.length,
            itemBuilder: (context, index) {
              int lyricSnippetIndex = getSnippetIndexWithID(beforeSnippetIDs[index]);
              return Text(lyricAppearance[lyricSnippetIndex]);
            },
          ),
        ),
        */
      ],
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
