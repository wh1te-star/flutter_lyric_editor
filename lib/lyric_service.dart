import 'package:lyric_editor/signal_structure.dart';
import 'package:rxdart/rxdart.dart';

class LyricService {
  final PublishSubject<dynamic> masterSubject;

  LyricService({required this.masterSubject}) {
    masterSubject.stream.listen((signal) {});
  }
}
