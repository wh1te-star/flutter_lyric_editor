import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/lyric_snippet.dart';
import 'package:lyric_editor/sorted_list.dart';
import 'package:xml/xml.dart' as xml;
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class TimingService {
  final PublishSubject<dynamic> masterSubject;
  String rawLyricText = "";
  late final List<LyricSnippet> lyricSnippetList;
  Future<void>? _loadLyricsFuture;

  SortedList<int> timingPoints =
      SortedList<int>([1, 4, 5, 16, 24, 36, 46, 50, 67, 90]);
  //List<int> sectionPoints = [82];

  TimingService({required this.masterSubject}) {
    masterSubject.stream.listen((signal) {
      if (signal is RequestToAddLyricTiming) {
        timingPoints.add(signal.characterPosition);
        masterSubject.add(NotifyTimingPointAdded(signal.characterPosition));
      }
      if (signal is RequestToDeleteLyricTiming) {
        timingPoints.remove(signal.characterPosition);
        masterSubject.add(NotifyTimingPointDeletion(signal.characterPosition));
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
    } catch (e) {
      debugPrint("Error loading lyrics: $e");
    }
  }

  List<LyricSnippet> parseLyric(String rawLyricText) {
    final document = xml.XmlDocument.parse(rawLyricText);
    final vocalists = document.findAllElements('Vocalist');
    List<LyricSnippet> snippets = [];

    for (var vocalist in vocalists) {
      final vocalistName = vocalist.getAttribute('name')!;
      final lineTimestamps = vocalist.findElements('LineTimestamp');

      for (var lineTimestamp in lineTimestamps) {
        final startTime =
            parseTimestamp(lineTimestamp.getAttribute('startTime')!);
        final endTime = parseTimestamp(lineTimestamp.getAttribute('endTime')!);
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
          sentence: sentence,
          startTimestamp: startTime,
          endTimestamp: endTime,
          timingPoints: timingPoints,
        ));
      }
    }

    return snippets;
  }

  int parseTimestamp(String timestamp) {
    final parts = timestamp.split(':');
    final minutes = int.parse(parts[0]);
    final secondsParts = parts[1].split('.');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(secondsParts[1]);
    return (minutes * 60 + seconds) * 1000 + milliseconds;
  }

  Future<void> printLyric() async {
    if (_loadLyricsFuture != null) {
      await _loadLyricsFuture;
    }
    //String first30Chars = rawLyricText.substring(0, 30);
    //debugPrint(first30Chars);
  }
}
