import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation_map.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/section/section_list.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist_color_map.dart';
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

  String serialize(Tuple3<LyricSnippetMap, VocalistColorMap, SectionList> data) {
    LyricSnippetMap lyricSnippetMap = data.item1;
    VocalistColorMap vocalistColorMap = data.item2;
    SectionList sectionList = data.item3;

    final XmlBuilder builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(rootElement, nest: () {
      for (LyricSnippet snippet in lyricSnippetMap.values) {
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

  Tuple3<LyricSnippetMap, VocalistColorMap, SectionList> deserialize(String rawText) {
    LyricSnippetMap lyricSnippetMap = LyricSnippetMap.empty;
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
      final SentenceSegmentList sentenceSegmentList = SentenceSegmentList(wordTimestamps.map((XmlElement wordTimestamp) {
        final int duration = parseTimestamp(wordTimestamp.getAttribute(sentenceSegmentDurationAttribute)!);
        final word = wordTimestamp.innerText;
        return SentenceSegment(
          word,
          Duration(milliseconds: duration),
        );
      }).toList());

      final VocalistID vocalistID = vocalistColorMap.getVocalistIDByName(vocalistName);
      final Timing timing = Timing(startTimestamp: SeekPosition(startTimestamp), sentenceSegmentList: sentenceSegmentList);

      lyricSnippetMap = lyricSnippetMap.addLyricSnippet(LyricSnippet(
        vocalistID: vocalistID,
        timing: timing,
        annotationMap: AnnotationMap({}),
      ));
    }

    return Tuple3<LyricSnippetMap, VocalistColorMap, SectionList>(
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
