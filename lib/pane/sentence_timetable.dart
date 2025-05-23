import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/dialog/sentence_detail_dialog.dart';
import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/pane/timeline_pane/rectangle_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/triangle_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/timeline_pane.dart';
import 'package:lyric_editor/service/timing_service.dart';

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
  double timingPointIndicatorHeight = 5.0;
  double annotationItemHeight = 15.0;
  double annotationSentenceMargin = 1.0;
  double sentenceItemHeight = 30.0;
  double bottomMargin = 2.0;
  double get trackHeight {
    return topMargin + timingPointIndicatorHeight + annotationItemHeight + annotationSentenceMargin + sentenceItemHeight + bottomMargin;
  }

  double timingPointIndicatorWidth = 5.0;

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
    List<Widget> timingPointIndicatorWidgets = [];
    List<Widget> annotationItemWidgets = [];
    List<Widget> annotationTimingPointIndicatorWidgets = [];

    Map<SentenceID, Sentence> sentences = timingService.getSentencesByVocalistID(vocalistID).map;
    sentenceTracks = getTrack(sentences);
    for (MapEntry<SentenceID, Sentence> entry in sentences.entries) {
      SentenceID sentenceID = entry.key;
      Sentence sentence = entry.value;

      sentenceItemWidgets.add(getSentenceItemWidget(sentenceID, sentence));
      timingPointIndicatorWidgets += getTimingPointIndicatorWidgets(sentenceID, sentence);
      annotationItemWidgets += getAnnotationItemWidget(sentenceID, sentence);
      annotationTimingPointIndicatorWidgets += getAnnotationTimingPointIndicatorWidgets(sentenceID, sentence);
    }
    return Stack(
      children: sentenceItemWidgets + timingPointIndicatorWidgets + annotationItemWidgets + annotationTimingPointIndicatorWidgets,
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
      top: trackHeight * sentenceTracks[sentenceID]! + topMargin + timingPointIndicatorHeight + annotationItemHeight + annotationSentenceMargin,
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
        child: CustomPaint(
          size: itemSize,
          painter: RectanglePainter(
            sentence: sentence.sentence,
            color: vocalistColor,
            isSelected: timelinePaneProvider.selectingSentence.contains(sentenceID),
            borderLineWidth: 2.0,
          ),
        ),
      ),
    );
    return sentenceItem;
  }

  List<Widget> getAnnotationItemWidget(SentenceID sentenceID, Sentence sentence) {
    List<Widget> annotaitonItems = [];

    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Color vocalistColor = Color(timingService.vocalistColorMap[vocalistID]!.color);

    for (MapEntry<PhrasePosition, Annotation> entry in sentence.annotationMap.map.entries) {
      PhrasePosition phrasePosition = entry.key;
      Annotation annotation = entry.value;
      Size itemSize = Size(
        duration2Length(annotation.endTimestamp.position - annotation.startTimestamp.position),
        annotationItemHeight,
      );
      Widget annotationItem = Positioned(
        left: duration2Length(annotation.startTimestamp.position),
        top: trackHeight * sentenceTracks[sentenceID]! + topMargin + timingPointIndicatorHeight,
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
      annotaitonItems.add(annotationItem);
    }
    return annotaitonItems;
  }

  List<Widget> getTimingPointIndicatorWidgets(SentenceID sentenceID, Sentence sentence) {
    Size itemSize = Size(
      timingPointIndicatorWidth,
      timingPointIndicatorHeight,
    );

    List<Widget> indicatorWidgets = [];
    for (int index = 0; index < sentence.timingPoints.length; index++) {
      TimingPoint timingPoint = sentence.timingPoints[index];
      Widget indicator = Positioned(
        left: duration2Length(sentence.startTimestamp.position + timingPoint.seekPosition.position),
        top: trackHeight * sentenceTracks[sentenceID]! + topMargin + timingPointIndicatorHeight + annotationItemHeight + annotationSentenceMargin + sentenceItemHeight,
        child: CustomPaint(
          size: itemSize,
          painter: TrianglePainter(
            x: 0.0,
            y: 0.0,
            width: timingPointIndicatorWidth,
            height: -timingPointIndicatorHeight,
          ),
        ),
      );
      indicatorWidgets.add(indicator);
    }
    return indicatorWidgets;
  }

  List<Widget> getAnnotationTimingPointIndicatorWidgets(SentenceID sentenceID, Sentence sentence) {
    Size itemSize = Size(
      timingPointIndicatorWidth,
      timingPointIndicatorHeight,
    );

    List<Widget> indicatorWidgets = [];
    for (MapEntry<PhrasePosition, Annotation> entry in sentence.annotationMap.map.entries) {
      PhrasePosition phrasePosition = entry.key;
      Annotation annotation = entry.value;
      for (int index = 0; index < annotation.timingPoints.length; index++) {
        TimingPoint timingPoint = annotation.timingPoints[index];
        Widget indicator = Positioned(
          left: duration2Length(annotation.startTimestamp.position + timingPoint.seekPosition.position),
          top: trackHeight * sentenceTracks[sentenceID]! + topMargin,
          child: CustomPaint(
            size: itemSize,
            painter: TrianglePainter(
              x: 0.0,
              y: timingPointIndicatorHeight,
              width: timingPointIndicatorWidth,
              height: timingPointIndicatorHeight,
            ),
          ),
        );
        indicatorWidgets.add(indicator);
      }
    }
    return indicatorWidgets;
  }
}
