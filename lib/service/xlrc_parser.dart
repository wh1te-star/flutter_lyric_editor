import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby_map.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/section/section_list.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timetable.dart';
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

  static const String sentenceElement = "LineTimestamp";
  static const String sentenceVocalistNameAttribute = "vocalistName";
  static const String sentenceStartTimestampAttribute = "startTime";
  static const String sentenceSegmentElement = "WordTimestamp";
  static const String sentenceSegmentDurationAttribute = "time";

  String serialize(Tuple3<SentenceMap, VocalistColorMap, SectionList> data) {
    SentenceMap sentenceMap = data.item1;
    VocalistColorMap vocalistColorMap = data.item2;
    SectionList sectionList = data.item3;

    final XmlBuilder builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(rootElement, nest: () {
      for (Sentence sentence in sentenceMap.values) {
        builder.element(sentenceElement, attributes: {
          sentenceVocalistNameAttribute: vocalistColorMap[sentence.vocalistID]!.name,
          sentenceStartTimestampAttribute: formatTimestamp(sentence.startTimestamp.position),
        }, nest: () {
          for (var sentenceSegment in sentence.sentenceSegments) {
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
    SentenceMap sentenceMap = SentenceMap.empty;
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

    final Iterable<XmlElement> lineTimestamps = document.findAllElements(sentenceElement);
    for (XmlElement lineTimestamp in lineTimestamps) {
      final int startTimestamp = parseTimestamp(lineTimestamp.getAttribute(sentenceStartTimestampAttribute)!);
      final String vocalistName = lineTimestamp.getAttribute(sentenceVocalistNameAttribute)!;
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

      sentenceMap = sentenceMap.addSentence(Sentence(
        vocalistID: vocalistID,
        timing: timing,
        annotationMap: AnnotationMap({}),
      ));
    }

    return Tuple3<SentenceMap, VocalistColorMap, SectionList>(
      sentenceMap,
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
