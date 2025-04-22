import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';

void main() {
  group('test', () {
    Timing testData1 = Timing(
      startTimestamp: SeekPosition(2000),
      sentenceSegmentList: SentenceSegmentList([
        SentenceSegment("abcde", Duration(milliseconds: 1000)),
        SentenceSegment("", Duration(milliseconds: 1000)),
        SentenceSegment("fghij", Duration(milliseconds: 1000)),
        SentenceSegment("", Duration(milliseconds: 1000)),
        SentenceSegment("klmno", Duration(milliseconds: 1000)),
        SentenceSegment("", Duration(milliseconds: 1000)),
        SentenceSegment("pqrst", Duration(milliseconds: 1000)),
      ]),
    );
    setUp(() {});

    test('Test the getSegmentIndexFromSeekPosition() function', () {
      SentenceSegmentIndex result;
      result = testData1.getSegmentIndexFromSeekPosition(SeekPosition(1000));
      expect(result, SentenceSegmentIndex.empty);
      result = testData1.getSegmentIndexFromSeekPosition(SeekPosition(2500));
      expect(result, SentenceSegmentIndex(0));
      result = testData1.getSegmentIndexFromSeekPosition(SeekPosition(3500));
      expect(result, SentenceSegmentIndex(1));
      result = testData1.getSegmentIndexFromSeekPosition(SeekPosition(4500));
      expect(result, SentenceSegmentIndex(2));
      result = testData1.getSegmentIndexFromSeekPosition(SeekPosition(5500));
      expect(result, SentenceSegmentIndex(3));
      result = testData1.getSegmentIndexFromSeekPosition(SeekPosition(6500));
      expect(result, SentenceSegmentIndex(4));
    });
  });
}
