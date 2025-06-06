import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/dialog/sentence_detail_dialog.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/pane/timeline_pane/reorderable_list.dart/sentence_item.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/pane/timeline_pane/reorderable_list.dart/rectangle_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/reorderable_list.dart/triangle_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/timeline_pane.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';

class SentenceTimeline extends ConsumerStatefulWidget {
  VocalistID vocalistID;

  SentenceTimeline(this.vocalistID, {super.key});

  @override
  _SentenceTimelineState createState() => _SentenceTimelineState(
        vocalistID,
      );
}

class _SentenceTimelineState extends ConsumerState<SentenceTimeline> {
  double topMargin = 5.0;
  double timingIndicatorHeight = 5.0;
  double rubyItemHeight = 15.0;
  double rubySentenceMargin = 1.0;
  double sentenceItemHeight = 30.0;
  double bottomMargin = 2.0;
  double get trackHeight {
    return topMargin + timingIndicatorHeight + rubyItemHeight + rubySentenceMargin + sentenceItemHeight + bottomMargin;
  }

  double timingIndicatorWidth = 5.0;

  VocalistID vocalistID;
  Map<SentenceID, int> sentenceTracks = {};

  _SentenceTimelineState(
    this.vocalistID,
  );

  double length2Duration(double length) {
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
    int intervalDuration = timelinePaneProvider.intervalDuration;
    double intervalLength = timelinePaneProvider.intervalLength;
    return length * intervalDuration / intervalLength;
  }

  double duration2Length(int duration) {
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
    int intervalDuration = timelinePaneProvider.intervalDuration;
    double intervalLength = timelinePaneProvider.intervalLength;
    return duration.toDouble() * intervalLength / intervalDuration;
  }

  @override
  Widget build(BuildContext context) {
    final TimingService timingService = ref.read(timingMasterProvider);
    List<Widget> sentenceItemWidgets = [];
    List<Widget> timingIndicatorWidgets = [];
    List<Widget> rubyItemWidgets = [];
    List<Widget> rubyTimingIndicatorWidgets = [];

    Map<SentenceID, Sentence> sentences = timingService.getSentencesByVocalistID(vocalistID).map;
    sentenceTracks = getTrack(sentences);
    for (MapEntry<SentenceID, Sentence> entry in sentences.entries) {
      SentenceID sentenceID = entry.key;
      Sentence sentence = entry.value;

      sentenceItemWidgets.add(getSentenceItemWidget(sentenceID, sentence));
      timingIndicatorWidgets += getTimingIndicatorWidgets(sentenceID, sentence);
      rubyItemWidgets += getRubyItemWidget(sentenceID, sentence);
      rubyTimingIndicatorWidgets += getRubyTimingIndicatorWidgets(sentenceID, sentence);
    }
    return Stack(
      children: sentenceItemWidgets + timingIndicatorWidgets + rubyItemWidgets + rubyTimingIndicatorWidgets,
    );
  }

  Map<SentenceID, int> getTrack(Map<SentenceID, Sentence> sentences) {
    Map<SentenceID, int> tracks = {};
    int currentTrack = 0;
    int previousEndtime = 0;
    for (MapEntry<SentenceID, Sentence> entry in sentences.entries) {
      SentenceID id = entry.key;
      Sentence sentence = entry.value;

      if (sentence.sentence == "") {
        tracks[id] = -1;
        continue;
      }

      final endtime = sentence.endTimestamp;
      if (sentence.startTimestamp.position < previousEndtime) {
        currentTrack++;
      } else {
        currentTrack = 0;
        previousEndtime = endtime.position;
      }

      tracks[id] = currentTrack;
    }

    return tracks;
  }

  Widget getSentenceItemWidget(SentenceID sentenceID, Sentence sentence) {
    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Color vocalistColor = Color(timingService.vocalistColorMap[vocalistID]!.color);

    Size itemSize = Size(
      duration2Length(sentence.endTimestamp.position - sentence.startTimestamp.position),
      sentenceItemHeight,
    );
    Widget sentenceItem = Positioned(
      left: duration2Length(sentence.startTimestamp.position),
      top: trackHeight * sentenceTracks[sentenceID]! + topMargin + timingIndicatorHeight + rubyItemHeight + rubySentenceMargin,
      child: GestureDetector(
        onTap: () {
          List<SentenceID> selectingSentences = timelinePaneProvider.selectingSentence;
          if (selectingSentences.contains(sentenceID)) {
            timelinePaneProvider.selectingSentence.remove(sentenceID);
          } else {
            timelinePaneProvider.selectingSentence.add(sentenceID);
          }
          setState(() {});
        },
        onDoubleTap: () {
          displaySentenceDetailDialog(context, sentenceID, sentence);
        },
        child: SentenceItem(
          width: duration2Length(sentence.startTimestamp.durationUntil(sentence.endTimestamp).inMilliseconds),
          height: sentenceItemHeight,
          sentence: sentence.sentence,
          vocalistColor: vocalistColor,
        ),
      ),
    );
    return sentenceItem;
  }

  List<Widget> getRubyItemWidget(SentenceID sentenceID, Sentence sentence) {
    List<Widget> annotaitonItems = [];

    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Color vocalistColor = Color(timingService.vocalistColorMap[vocalistID]!.color);

    for (MapEntry<WordRange, Ruby> entry in sentence.rubyMap.map.entries) {
      WordRange wordRange = entry.key;
      Ruby ruby = entry.value;
      Size itemSize = Size(
        duration2Length((ruby.startTimestamp.absolute.durationUntil(ruby.endTimestamp).inMilliseconds)),
        rubyItemHeight,
      );
      Widget rubyItem = Positioned(
        left: duration2Length(ruby.startTimestamp.absolute.position),
        top: trackHeight * sentenceTracks[sentenceID]! + topMargin + timingIndicatorHeight,
        child: GestureDetector(
          onTap: () {
            List<SentenceID> selectingSentences = timelinePaneProvider.selectingSentence;
            if (selectingSentences.contains(sentenceID)) {
              timelinePaneProvider.selectingSentence.remove(sentenceID);
            } else {
              timelinePaneProvider.selectingSentence.add(sentenceID);
            }
            setState(() {});
          },
          child: CustomPaint(
            size: itemSize,
            painter: RectanglePainter(
              sentence: "",
              color: vocalistColor,
              isSelected: timelinePaneProvider.selectingSentence.contains(sentenceID),
              borderLineWidth: 2.0,
            ),
          ),
        ),
      );
      annotaitonItems.add(rubyItem);
    }
    return annotaitonItems;
  }

  List<Widget> getTimingIndicatorWidgets(SentenceID sentenceID, Sentence sentence) {
    Size itemSize = Size(
      timingIndicatorWidth,
      timingIndicatorHeight,
    );

    List<Widget> indicatorWidgets = [];
    for (int index = 0; index < sentence.timings.length; index++) {
      TimingIndex timingIndex = TimingIndex(index);
      Timing timing = sentence.timings[timingIndex];
      Widget indicator = Positioned(
        left: duration2Length(timing.seekPosition.absolute.position),
        top: trackHeight * sentenceTracks[sentenceID]! + topMargin + timingIndicatorHeight + rubyItemHeight + rubySentenceMargin + sentenceItemHeight,
        child: CustomPaint(
          size: itemSize,
          painter: TrianglePainter(
            x: 0.0,
            y: 0.0,
            width: timingIndicatorWidth,
            height: -timingIndicatorHeight,
          ),
        ),
      );
      indicatorWidgets.add(indicator);
    }
    return indicatorWidgets;
  }

  List<Widget> getRubyTimingIndicatorWidgets(SentenceID sentenceID, Sentence sentence) {
    Size itemSize = Size(
      timingIndicatorWidth,
      timingIndicatorHeight,
    );

    List<Widget> indicatorWidgets = [];
    for (MapEntry<WordRange, Ruby> entry in sentence.rubyMap.map.entries) {
      WordRange wordRange = entry.key;
      Ruby ruby = entry.value;
      for (int index = 0; index < ruby.timings.length; index++) {
        TimingIndex timingIndex = TimingIndex(index);
        Timing timing = ruby.timings[timingIndex];
        Widget indicator = Positioned(
          left: duration2Length(timing.seekPosition.absolute.position),
          top: trackHeight * sentenceTracks[sentenceID]! + topMargin,
          child: CustomPaint(
            size: itemSize,
            painter: TrianglePainter(
              x: 0.0,
              y: timingIndicatorHeight,
              width: timingIndicatorWidth,
              height: timingIndicatorHeight,
            ),
          ),
        );
        indicatorWidgets.add(indicator);
      }
    }
    return indicatorWidgets;
  }
}
