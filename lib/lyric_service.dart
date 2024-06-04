import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/sorted_list.dart';
import 'package:xml/xml.dart' as xml;
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class LyricService {
  final PublishSubject<dynamic> masterSubject;
  var rawLyricText = "";
  late final String parsedLyricList;
  Future<void>? _loadLyricsFuture;

  SortedList<int> timingPoints =
      SortedList<int>([1, 4, 5, 16, 24, 36, 46, 50, 67, 90]);
  SortedList<int> linefeedPoints = SortedList<int>([19, 38, 57, 70, 98, 100]);
  //List<int> sectionPoints = [82];

  LyricService({required this.masterSubject}) {
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

      parsedLyricList = parseLyric(rawLyricText);
      masterSubject.add(
          NotifyLyricParsed(parsedLyricList, timingPoints, linefeedPoints));
    } catch (e) {
      debugPrint("Error loading lyrics: $e");
    }
  }

  String parseLyric(String rawLyricText) {
    xml.XmlDocument parsedXmlText = xml.XmlDocument.parse(rawLyricText);
    final lineTimestamps = parsedXmlText.findAllElements('LineTimestamp');
    String sentences = "";

    for (var timestamp in lineTimestamps) {
      String sentence = '';
      final wordTimestamps = timestamp.findElements('WordTimestamp');

      for (var wordTimestamp in wordTimestamps) {
        sentence += wordTimestamp.innerText;
      }

      if (sentence.isNotEmpty) {
        sentences += sentence;
      }
    }

    return sentences;
  }

  Future<void> printLyric() async {
    if (_loadLyricsFuture != null) {
      await _loadLyricsFuture;
    }
    //String first30Chars = rawLyricText.substring(0, 30);
    //debugPrint(first30Chars);
  }
}
