import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/dialog/sentence_detail_dialog.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/reading/reading.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/pane/timeline_pane/rectangle_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/triangle_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/timeline_pane.dart';
import 'package:lyric_editor/service/timing_service.dart';

class SnippetTimeline extends ConsumerStatefulWidget {
  VocalistID vocalistID;

  SnippetTimeline(this.vocalistID, {super.key});

  @override
  _SnippetTimelineState createState() => _SnippetTimelineState(
        vocalistID,
      );
}

class _SnippetTimelineState extends ConsumerState<SnippetTimeline> {
  double topMargin = 5.0;
  double timingPointIndicatorHeight = 5.0;
  double readingItemHeight = 15.0;
  double readingSnippetMargin = 1.0;
  double snippetItemHeight = 30.0;
  double bottomMargin = 2.0;
  double get trackHeight {
    return topMargin + timingPointIndicatorHeight + readingItemHeight + readingSnippetMargin + snippetItemHeight + bottomMargin;
  }

  double timingPointIndicatorWidth = 5.0;

  VocalistID vocalistID;
  Map<SentenceID, int> sentenceTracks = {};

  _SnippetTimelineState(
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
    List<Widget> snippetItemWidgets = [];
    List<Widget> timingPointIndicatorWidgets = [];
    List<Widget> readingItemWidgets = [];
    List<Widget> readingTimingPointIndicatorWidgets = [];

    Map<SentenceID, Sentence> snippets = timingService.getLyricSnippetByVocalistID(vocalistID).map;
    sentenceTracks = getTrack(snippets);
    for (MapEntry<SentenceID, Sentence> entry in snippets.entries) {
      SentenceID snippetID = entry.key;
      Sentence snippet = entry.value;

      snippetItemWidgets.add(getSnippetItemWidget(snippetID, snippet));
      timingPointIndicatorWidgets += getTimingPointIndicatorWidgets(snippetID, snippet);
      readingItemWidgets += getReadingItemWidget(snippetID, snippet);
      readingTimingPointIndicatorWidgets += getReadingTimingIndicatorWidgets(snippetID, snippet);
    }
    return Stack(
      children: snippetItemWidgets + timingPointIndicatorWidgets + readingItemWidgets + readingTimingPointIndicatorWidgets,
    );
  }

  Map<SentenceID, int> getTrack(Map<SentenceID, Sentence> sentences) {
    Map<SentenceID, int> tracks = {};
    int currentTrack = 0;
    int previousEndtime = 0;
    for (MapEntry<SentenceID, Sentence> entry in sentences.entries) {
      SentenceID id = entry.key;
      Sentence snippet = entry.value;

      if (snippet.sentence == "") {
        tracks[id] = -1;
        continue;
      }

      final endtime = snippet.endTimestamp;
      if (snippet.startTimestamp.position < previousEndtime) {
        currentTrack++;
      } else {
        currentTrack = 0;
        previousEndtime = endtime.position;
      }

      tracks[id] = currentTrack;
    }

    return tracks;
  }

  Widget getSnippetItemWidget(SentenceID sentenceID, Sentence sentence) {
    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Color vocalistColor = Color(timingService.vocalistColorMap[vocalistID]!.color);

    Size itemSize = Size(
      duration2Length(sentence.endTimestamp.position - sentence.startTimestamp.position),
      snippetItemHeight,
    );
    Widget snippetItem = Positioned(
      left: duration2Length(sentence.startTimestamp.position),
      top: trackHeight * sentenceTracks[sentenceID]! + topMargin + timingPointIndicatorHeight + readingItemHeight + readingSnippetMargin,
      child: GestureDetector(
        onTap: () {
          List<SentenceID> selectingSnippets = timelinePaneProvider.selectingSentences;
          if (selectingSnippets.contains(sentenceID)) {
            timelinePaneProvider.selectingSentences.remove(sentenceID);
          } else {
            timelinePaneProvider.selectingSentences.add(sentenceID);
          }
          setState(() {});
        },
        onDoubleTap: () {
          displaySnippetDetailDialog(context, sentenceID, sentence);
        },
        child: CustomPaint(
          size: itemSize,
          painter: RectanglePainter(
            sentence: sentence.sentence,
            color: vocalistColor,
            isSelected: timelinePaneProvider.selectingSentences.contains(sentenceID),
            borderLineWidth: 2.0,
          ),
        ),
      ),
    );
    return snippetItem;
  }

  List<Widget> getReadingItemWidget(SentenceID sentenceID, Sentence sentence) {
    List<Widget> annotaitonItems = [];

    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Color vocalistColor = Color(timingService.vocalistColorMap[vocalistID]!.color);

    for (MapEntry<PhrasePosition, Reading> entry in sentence.readingMap.map.entries) {
      PhrasePosition range = entry.key;
      Reading reading = entry.value;
      Size itemSize = Size(
        duration2Length(reading.endTime.position - reading.startTime.position),
        readingItemHeight,
      );
      Widget readingItem = Positioned(
        left: duration2Length(reading.startTime.position),
        top: trackHeight * sentenceTracks[sentenceID]! + topMargin + timingPointIndicatorHeight,
        child: GestureDetector(
          onTap: () {
            List<SentenceID> selectingSnippets = timelinePaneProvider.selectingSentences;
            if (selectingSnippets.contains(sentenceID)) {
              timelinePaneProvider.selectingSentences.remove(sentenceID);
            } else {
              timelinePaneProvider.selectingSentences.add(sentenceID);
            }
            setState(() {});
          },
          child: CustomPaint(
            size: itemSize,
            painter: RectanglePainter(
              sentence: "",
              color: vocalistColor,
              isSelected: timelinePaneProvider.selectingSentences.contains(sentenceID),
              borderLineWidth: 2.0,
            ),
          ),
        ),
      );
      annotaitonItems.add(readingItem);
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
      Timing timingPoint = sentence.timingPoints[index];
      Widget indicator = Positioned(
        left: duration2Length(sentence.startTimestamp.position + timingPoint.seekPosition.position),
        top: trackHeight * sentenceTracks[sentenceID]! + topMargin + timingPointIndicatorHeight + readingItemHeight + readingSnippetMargin + snippetItemHeight,
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

  List<Widget> getReadingTimingIndicatorWidgets(SentenceID sentenceID, Sentence sentence) {
    Size itemSize = Size(
      timingPointIndicatorWidth,
      timingPointIndicatorHeight,
    );

    List<Widget> indicatorWidgets = [];
    for (MapEntry<PhrasePosition, Reading> entry in sentence.readingMap.map.entries) {
      Reading reading = entry.value;
      for (int index = 0; index < reading.timingPoints.length; index++) {
        Timing timingPoint = reading.timingPoints[index];
        Widget indicator = Positioned(
          left: duration2Length(reading.startTime.position + timingPoint.seekPosition.position),
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
