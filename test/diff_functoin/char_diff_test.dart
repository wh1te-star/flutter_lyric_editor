import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/diff_function/diff_segment.dart';
import 'package:lyric_editor/diff_function/char_diff.dart';

void main() {
  group('diff function test', () {
    setUp(() {});

    test('When not editting any substring.', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abcdefgh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<DiffSegment> expected = [
        DiffSegment("abcdefgh", "abcdefgh"),
      ];

      expect(diff.getDiffSegments(), equals(expected));
    });

    test('When editting a part of the before string. (e -> xx)', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abcdxxfgh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<DiffSegment> expected = [
        DiffSegment("abcd", "abcd"),
        DiffSegment("e", "xx"),
        DiffSegment("fgh", "fgh"),
      ];

      expect(diff.getDiffSegments(), equals(expected));
    });

    test('When deleting a part of the before string. (delete e)', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abcdfgh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<DiffSegment> expected = [
        DiffSegment("abcd", "abcd"),
        DiffSegment("e", ""),
        DiffSegment("fgh", "fgh"),
      ];

      expect(diff.getDiffSegments(), equals(expected));
    });

    test('When adding a part of the before string. (add xx)', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abcdexxfgh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<DiffSegment> expected = [
        DiffSegment("abcde", "abcde"),
        DiffSegment("", "xx"),
        DiffSegment("fgh", "fgh"),
      ];

      expect(diff.getDiffSegments(), equals(expected));
    });

    test('When editting 2 parts of the before string. (add xx and delete fg)', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abxxcdeh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<DiffSegment> expected = [
        DiffSegment("ab", "ab"),
        DiffSegment("", "xx"),
        DiffSegment("cde", "cde"),
        DiffSegment("fg", ""),
        DiffSegment("h", "h"),
      ];

      expect(diff.getDiffSegments(), equals(expected));
    });
  });
}
