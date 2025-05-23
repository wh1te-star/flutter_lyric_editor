import 'package:flutter_test/flutter_test.dart';
import 'package:lyric_editor/diff_function/word_diff.dart';
import 'package:lyric_editor/diff_function/char_diff.dart';

void main() {
  group('diff function test', () {
    setUp(() {});

    test('When not editting any substring.', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abcdefgh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<WordDiff> expected = [
        WordDiff("abcdefgh", "abcdefgh"),
      ];

      expect(diff.getWordDiffs(), equals(expected));
    });

    test('When editting a part of the before string. (e -> xx)', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abcdxxfgh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<WordDiff> expected = [
        WordDiff("abcd", "abcd"),
        WordDiff("e", "xx"),
        WordDiff("fgh", "fgh"),
      ];

      expect(diff.getWordDiffs(), equals(expected));
    });

    test('When deleting a part of the before string. (delete e)', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abcdfgh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<WordDiff> expected = [
        WordDiff("abcd", "abcd"),
        WordDiff("e", ""),
        WordDiff("fgh", "fgh"),
      ];

      expect(diff.getWordDiffs(), equals(expected));
    });

    test('When adding a part of the before string. (add xx)', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abcdexxfgh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<WordDiff> expected = [
        WordDiff("abcde", "abcde"),
        WordDiff("", "xx"),
        WordDiff("fgh", "fgh"),
      ];

      expect(diff.getWordDiffs(), equals(expected));
    });

    test('When editting 2 parts of the before string. (add xx and delete fg)', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abxxcdeh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<WordDiff> expected = [
        WordDiff("ab", "ab"),
        WordDiff("", "xx"),
        WordDiff("cde", "cde"),
        WordDiff("fg", ""),
        WordDiff("h", "h"),
      ];

      expect(diff.getWordDiffs(), equals(expected));
    });

    test('Edit the first part', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "xxcdefgh";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<WordDiff> expected = [
        WordDiff("ab", "xx"),
        WordDiff("cdefgh", "cdefgh"),
      ];

      expect(diff.getWordDiffs(), equals(expected));
    });

    test('Edit the end part', () {
      const String beforeStr = "abcdefgh";
      const String afterStr = "abcdefxx";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<WordDiff> expected = [
        WordDiff("abcdef", "abcdef"),
        WordDiff("gh", "xx"),
      ];

      print(diff);

      expect(diff.getWordDiffs(), equals(expected));
    });

    test('The diff should have has at least 2 routes but only one route was found.', skip: true, () {
      const String beforeStr = "Welcometeatime";
      const String afterStr = "Welcometime";
      final CharDiff diff = CharDiff(beforeStr, afterStr);

      final List<WordDiff> expected = [
        WordDiff("Welcome", "Welcome"),
        WordDiff("tea", ""),
        WordDiff("time", "time"),
      ];

      print(diff);

      expect(diff.getLeastWordDiffOne(), equals(expected));
    });
  });
}
