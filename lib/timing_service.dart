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
      if (signal is NotifyAudioFileLoaded) {
        audioDuration = signal.millisec;
      }

      if (signal is RequestToMakeSnippet) {
        int index = lyricSnippetList
            .indexWhere((snippet) => snippet.id == signal.snippetID);
        String beforeString =
            lyricSnippetList[index].sentence.substring(0, signal.startCharPos);
        String middleString = lyricSnippetList[index]
            .sentence
            .substring(signal.startCharPos, signal.endCharPos);
        String afterString =
            lyricSnippetList[index].sentence.substring(signal.endCharPos);
        String vocalist = lyricSnippetList[index].vocalist;
        List<LyricSnippet> newSnippets = [];
        if (beforeString.isNotEmpty) {
          newSnippets.add(
            LyricSnippet(
              vocalist: vocalist,
              index: 1,
              sentence: beforeString,
              startTimestamp: lyricSnippetList[index].startTimestamp,
              timingPoints: [TimingPoint(beforeString.length, 2000)],
            ),
          );
        }
        if (middleString.isNotEmpty) {
          newSnippets.add(
            LyricSnippet(
              vocalist: vocalist,
              index: 2,
              sentence: middleString,
              startTimestamp: lyricSnippetList[index].startTimestamp + 2000,
              timingPoints: [TimingPoint(middleString.length, 2000)],
            ),
          );
        }
        if (afterString.isNotEmpty) {
          newSnippets.add(
            LyricSnippet(
              vocalist: vocalist,
              index: 3,
              sentence: afterString,
              startTimestamp: lyricSnippetList[index].startTimestamp + 4000,
              timingPoints: [TimingPoint(afterString.length, 2000)],
            ),
          );
        }
        if (index != -1) {
          lyricSnippetList.removeAt(index);
          lyricSnippetList.insertAll(index, newSnippets);
        }
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

    Map<String, int> idMap = {};
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

      if (!idMap.containsKey(vocalistName)) {
        idMap[vocalistName] = 1;
      } else {
        idMap[vocalistName] = idMap[vocalistName]! + 1;
      }

      snippets.add(LyricSnippet(
        vocalist: vocalistName,
        index: idMap[vocalistName]!,
        sentence: sentence,
        startTimestamp: startTime,
        timingPoints: timingPoints,
      ));
    }

    return snippets;
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
                .map((point) => point.seekPosition)
                .reduce((a, b) => a + b);
            final duration = nextPoint != null
                ? nextPoint.seekPosition - currentPoint.seekPosition
                : endtime - currentPoint.seekPosition;

            builder.element('WordTimestamp',
                attributes: {
                  'time': _formatDuration(Duration(milliseconds: duration)),
                },
                nest: snippet.sentence.substring(characterPosition,
                    characterPosition + currentPoint.characterLength));
            characterPosition += currentPoint.characterLength;
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
