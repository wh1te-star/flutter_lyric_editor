import 'package:lyric_editor/lyric_data/reading/reading.dart';
import 'package:lyric_editor/lyric_data/reading/reading_map.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/section/section_list.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timeline.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist_color_map.dart';
import 'package:tuple/tuple.dart';
import 'package:xml/xml.dart';

class XlrcParser {
  static const String rootElement = "LyricFile";

  static const String vocalistColorMapElement = "VocalistsList";
  static const String vocalistColorMapEntryElement = "VocalistInfo";
  static const String vocalistNameAttribute = "name";
  static const String vocalistColorAttribute = "color";
  static const String vocalistCombinationElement = "Vocalist";

  static const String lyricSnippetElement = "LineTimestamp";
  static const String lyricSnippetVocalistNameAttribute = "vocalistName";
  static const String lyricSnippetStartTimestampAttribute = "startTime";
  static const String sentenceSegmentElement = "WordTimestamp";
  static const String sentenceSegmentDurationAttribute = "time";

  String serialize(Tuple3<SentenceMap, VocalistColorMap, SectionList> data) {
    SentenceMap lyricSnippetMap = data.item1;
    VocalistColorMap vocalistColorMap = data.item2;
    SectionList sectionList = data.item3;

    final XmlBuilder builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(rootElement, nest: () {
      for (Sentence snippet in lyricSnippetMap.values) {
        builder.element(lyricSnippetElement, attributes: {
          lyricSnippetVocalistNameAttribute: vocalistColorMap[snippet.vocalistID]!.name,
          lyricSnippetStartTimestampAttribute: formatTimestamp(snippet.startTimestamp.position),
        }, nest: () {
          for (var sentenceSegment in snippet.sentenceSegments) {
            builder.element(
              sentenceSegmentElement,
              attributes: {
                sentenceSegmentDurationAttribute: formatTimestamp(sentenceSegment.duration.inMilliseconds),
              },
              nest: sentenceSegment.word,
            );
          }
        });
      }
    });

    final document = builder.buildDocument();
    return document.toXmlString(pretty: true, indent: '  ');
  }

  Tuple3<SentenceMap, VocalistColorMap, SectionList> deserialize(String rawText) {
    SentenceMap lyricSnippetMap = SentenceMap.empty;
    VocalistColorMap vocalistColorMap = VocalistColorMap.empty;
    SectionList sectionList = SectionList.empty;

    final document = XmlDocument.parse(rawText);

    final vocalistCombination = document.findAllElements(vocalistColorMapElement);
    for (XmlElement vocalistName in vocalistCombination) {
      final Iterable<XmlElement> colorElements = vocalistName.findElements(vocalistColorMapEntryElement);
      for (XmlElement colorElement in colorElements) {
        final String name = colorElement.getAttribute(vocalistNameAttribute)!;
        final int color = int.parse(colorElement.getAttribute(vocalistColorAttribute)!, radix: 16);

        final List<String> vocalistNames = colorElement.findAllElements(vocalistCombinationElement).map((e) => e.innerText).toList();
        if (vocalistNames.length == 1) {
          vocalistColorMap = vocalistColorMap.addVocalist(Vocalist(name: name, color: color + 0xFF000000));
        } else {
          vocalistColorMap = vocalistColorMap.addVocalistCombination(vocalistNames, color + 0xFF000000);
        }
      }
    }

    final Iterable<XmlElement> lineTimestamps = document.findAllElements(lyricSnippetElement);
    for (XmlElement lineTimestamp in lineTimestamps) {
      final int startTimestamp = parseTimestamp(lineTimestamp.getAttribute(lyricSnippetStartTimestampAttribute)!);
      final String vocalistName = lineTimestamp.getAttribute(lyricSnippetVocalistNameAttribute)!;
      final Iterable<XmlElement> wordTimestamps = lineTimestamp.findElements(sentenceSegmentElement);
      final WordList sentenceSegmentList = WordList(wordTimestamps.map((XmlElement wordTimestamp) {
        final int duration = parseTimestamp(wordTimestamp.getAttribute(sentenceSegmentDurationAttribute)!);
        final word = wordTimestamp.innerText;
        return Word(
          word,
          Duration(milliseconds: duration),
        );
      }).toList());

      final VocalistID vocalistID = vocalistColorMap.getVocalistIDByName(vocalistName);
      final Timeline timing = Timeline(startTime: SeekPosition(startTimestamp), wordList: sentenceSegmentList);

      lyricSnippetMap = lyricSnippetMap.addLyricSnippet(Sentence(
        vocalistID: vocalistID,
        timeline: timing,
        readingMap: ReadingMap({}),
      ));
    }

    return Tuple3<SentenceMap, VocalistColorMap, SectionList>(
      lyricSnippetMap,
      vocalistColorMap,
      sectionList,
    );
  }

  String formatTimestamp(int timestamp) {
    final minutes = (timestamp ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((timestamp % 60000) ~/ 1000).toString().padLeft(2, '0');
    final milliseconds = (timestamp % 1000).toString().padLeft(3, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  int parseTimestamp(String timestamp) {
    final List<String> parts = timestamp.split(':');
    final int minutes = int.parse(parts[0]);
    final List<String> secondsParts = parts[1].split('.');
    final int seconds = int.parse(secondsParts[0]);
    final int milliseconds = int.parse(secondsParts[1]);
    return (minutes * 60 + seconds) * 1000 + milliseconds;
  }
}
