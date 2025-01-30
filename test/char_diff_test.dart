import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/utility/char_diff.dart';

void main() {
  group('diff function test', () {
    setUp(() {});

    test('When editting a part of the before string. (e -> xx)', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abcdxxfgh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      expect(diff.segments, isEmpty);
    });
  });
}
