import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/lyric_snippet.dart';
import 'package:lyric_editor/sorted_list.dart';
import 'package:xml/xml.dart' as xml;
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';
import 'lyric_snippet.dart';

class TimingService {
  final PublishSubject<dynamic> masterSubject;
  String rawLyricText = "";
  late final List<LyricSnippet> lyricSnippetList;
  Future<void>? _loadLyricsFuture;
  int currentPosition = 0;
  int audioDuration = 180000;

  TimingService({required this.masterSubject}) {
    masterSubject.stream.listen((signal) {
      if (signal is RequestInitLyric) {
        String singlelineText =
            signal.rawText.replaceAll("\n", "").replaceAll("\r", "");
        lyricSnippetList.clear();
        lyricSnippetList.add(LyricSnippet(
          vocalist: "vocalist 1",
          index: 1,
          sentence: singlelineText,
          startTimestamp: 0,
          timingPoints: [TimingPoint(singlelineText.length, audioDuration)],
        ));
        masterSubject.add(NotifyLyricParsed(lyricSnippetList));
      }
      if (signal is RequestToAddLyricTiming) {
        List<LyricSnippet> filteredList = lyricSnippetList
            .where((snippet) => snippet.id == signal.snippetID)
            .toList();
        filteredList.forEach((LyricSnippet snippet) {
          snippet.timingPoints
              .add(TimingPoint(signal.characterPosition, signal.seekPosition));
        });
        masterSubject.add(NotifyTimingPointAdded(
            signal.snippetID, filteredList[0].timingPoints));
      }
      if (signal is RequestToDeleteLyricTiming) {
        masterSubject.add(NotifyTimingPointDeletion(signal.characterPosition));
      }
      if (signal is NotifySeekPosition) {
        currentPosition = signal.seekPosition;
      }
      if (signal is NotifyAudioFileLoaded) {
        audioDuration = signal.millisec;
      }

      if (signal is RequestToMakeSnippet) {
        int snippetMargin = 100;
        int index = lyricSnippetList
            .indexWhere((snippet) => snippet.id == signal.snippetID);
        String beforeString =
            lyricSnippetList[index].sentence.substring(0, signal.charPos);
        String afterString =
            lyricSnippetList[index].sentence.substring(signal.charPos);
        String vocalist = lyricSnippetList[index].vocalist;
        List<LyricSnippet> newSnippets = [];
        if (beforeString.isNotEmpty) {
          int snippetDuration =
              currentPosition - lyricSnippetList[index].startTimestamp;
          newSnippets.add(
            LyricSnippet(
              vocalist: vocalist,
              index: 0,
              sentence: beforeString,
              startTimestamp: lyricSnippetList[index].startTimestamp,
              timingPoints: [TimingPoint(beforeString.length, snippetDuration)],
            ),
          );
        }
        if (afterString.isNotEmpty) {
          int snippetDuration = lyricSnippetList[index].endTimestamp -
              lyricSnippetList[index].startTimestamp -
              currentPosition -
              snippetMargin;
          newSnippets.add(
            LyricSnippet(
              vocalist: vocalist,
              index: 0,
              sentence: afterString,
              startTimestamp: currentPosition + snippetMargin,
              timingPoints: [TimingPoint(afterString.length, snippetDuration)],
            ),
          );
        }
        if (index != -1) {
          lyricSnippetList.removeAt(index);
          lyricSnippetList.insertAll(index, newSnippets);
        }
        assignIndex(lyricSnippetList);
        masterSubject.add(NotifySnippetMade(lyricSnippetList));
      }
    });
    _loadLyricsFuture = loadLyrics();
  }

  Future<void> loadLyrics() async {
    try {
      rawLyricText = await rootBundle.loadString('assets/ウェルカムティーフレンド.lrc');
      masterSubject.add(NotifyLyricLoaded(rawLyricText));

      lyricSnippetList = parseLyric(rawLyricText);
      masterSubject.add(NotifyLyricParsed(lyricSnippetList));
      //writeTranslatedXmlToFile();
    } catch (e) {
      debugPrint("Error loading lyrics: $e");
    }
  }

  int parseTimestamp(String timestamp) {
    final parts = timestamp.split(':');
    final minutes = int.parse(parts[0]);
    final secondsParts = parts[1].split('.');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(secondsParts[1]);
    return (minutes * 60 + seconds) * 1000 + milliseconds;
  }

  List<LyricSnippet> parseLyric(String rawLyricText) {
    final document = xml.XmlDocument.parse(rawLyricText);
    final lineTimestamps = document.findAllElements('LineTimestamp');
    List<LyricSnippet> snippets = [];

    for (var lineTimestamp in lineTimestamps) {
      final startTime =
          parseTimestamp(lineTimestamp.getAttribute('startTime')!);
      final vocalistName = lineTimestamp.getAttribute('vocalistName')!;

      final wordTimestamps = lineTimestamp.findElements('WordTimestamp');
      String sentence = '';
      List<TimingPoint> timingPoints = [];

      for (var wordTimestamp in wordTimestamps) {
        final time = parseTimestamp(wordTimestamp.getAttribute('time')!);
        final word = wordTimestamp.innerText;
        timingPoints.add(TimingPoint(word.length, time));
        sentence += word;
      }
      snippets.add(LyricSnippet(
        vocalist: vocalistName,
        index: 0,
        sentence: sentence,
        startTimestamp: startTime,
        timingPoints: timingPoints,
      ));
    }

    assignIndex(snippets);

    return snippets;
  }

  void assignIndex(List<LyricSnippet> snippets) {
    Map<String, int> idMap = {};

    snippets.sort((LyricSnippet a, LyricSnippet b) =>
        a.startTimestamp.compareTo(b.startTimestamp));
    snippets.forEach((LyricSnippet snippet) {
      String vocalist = snippet.vocalist;
      if (!idMap.containsKey(vocalist)) {
        idMap[vocalist] = 1;
      } else {
        idMap[vocalist] = idMap[vocalist]! + 1;
      }
      snippet.index = idMap[vocalist]!;
    });
  }

  Future<void> writeTranslatedXmlToFile() async {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('Lyrics', nest: () {
      for (var snippet in lyricSnippetList) {
        builder.element('LineTimestamp', attributes: {
          'vocalistName': snippet.vocalist,
          'startTime': _formatTimestamp(snippet.startTimestamp),
        }, nest: () {
          int characterPosition = 0;
          for (int i = 0; i < snippet.timingPoints.length; i++) {
            final currentPoint = snippet.timingPoints[i];
            final nextPoint = i < snippet.timingPoints.length - 1
                ? snippet.timingPoints[i + 1]
                : null;

            final endtime = snippet.timingPoints
                .map((point) => point.wordDuration)
                .reduce((a, b) => a + b);
            final duration = nextPoint != null
                ? nextPoint.wordDuration - currentPoint.wordDuration
                : endtime - currentPoint.wordDuration;

            builder.element('WordTimestamp',
                attributes: {
                  'time': _formatDuration(Duration(milliseconds: duration)),
                },
                nest: snippet.sentence.substring(characterPosition,
                    characterPosition + currentPoint.wordLength));
            characterPosition += currentPoint.wordLength;
          }
        });
      }
    });

    /*
    final document = builder.buildDocument();
    final xmlString = document.toXmlString(pretty: true);
    debugPrint(xmlString);
    */
  }

  String _formatTimestamp(int timestamp) {
    final minutes = (timestamp ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((timestamp % 60000) ~/ 1000).toString().padLeft(2, '0');
    final milliseconds = (timestamp % 1000).toString().padLeft(3, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds =
        duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  Future<void> printLyric() async {
    if (_loadLyricsFuture != null) {
      await _loadLyricsFuture;
    }
    //String first30Chars = rawLyricText.substring(0, 30);
    //debugPrint(first30Chars);
  }
}
