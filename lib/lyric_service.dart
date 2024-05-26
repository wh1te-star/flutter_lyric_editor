import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart' as xml;
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class LyricService {
  final PublishSubject<dynamic> masterSubject;
  var rawLyricText = "";
  late final List<String> parsedLyricList;
  Future<void>? _loadLyricsFuture;

  LyricService({required this.masterSubject}) {
    masterSubject.stream.listen((signal) {});
    _loadLyricsFuture = loadLyrics();
  }

  Future<void> loadLyrics() async {
    try {
      rawLyricText = await rootBundle.loadString('assets/ウェルカムティーフレンド.lrc');
      masterSubject.add(NotifyLyricLoaded(rawLyricText));

      parsedLyricList = parseLyric(rawLyricText);
      masterSubject.add(NotifyLyricParsed(parsedLyricList));
    } catch (e) {
      debugPrint("Error loading lyrics: $e");
    }
  }

  List<String> parseLyric(String rawLyricText) {
    xml.XmlDocument parsedXmlText = xml.XmlDocument.parse(rawLyricText);
    List<String> words = [];
    parsedXmlText.findAllElements('WordTimestamp').forEach((element) {
      words.add(element.innerText);
    });
    return words;
  }

  Future<void> printLyric() async {
    if (_loadLyricsFuture != null) {
      await _loadLyricsFuture;
    }
    //String first30Chars = rawLyricText.substring(0, 30);
    //debugPrint(first30Chars);
  }
}
