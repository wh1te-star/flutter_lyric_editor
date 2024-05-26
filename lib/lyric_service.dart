import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class LyricService {
  final PublishSubject<dynamic> masterSubject;
  var rawLyricText = "";
  Future<void>? _loadLyricsFuture;

  LyricService({required this.masterSubject}) {
    masterSubject.stream.listen((signal) {});
    _loadLyricsFuture = loadLyrics();
  }

  Future<void> loadLyrics() async {
    try {
      rawLyricText = await rootBundle.loadString('assets/ウェルカムティーフレンド.lrc');
      masterSubject.add(NotifyLyricLoadCompleted(rawLyricText));
    } catch (e) {
      debugPrint("Error loading lyrics: $e");
    }
  }

  Future<void> printLyric() async {
    if (_loadLyricsFuture != null) {
      await _loadLyricsFuture;
    }
    //String first30Chars = rawLyricText.substring(0, 30);
    //debugPrint(first30Chars);
  }
}
