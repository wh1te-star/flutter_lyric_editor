import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist_color_map.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';

class ReorderableSentenceTimelineList extends StatefulWidget {
  final AbsoluteSeekPosition seekPosition;
  final VocalistColorMap vocalistColorMap;

  const ReorderableSentenceTimelineList({
    required this.seekPosition,
    required this.vocalistColorMap,
  });

  @override
  State<ReorderableSentenceTimelineList> createState(seekPosition, VocalistColorMap vocalistColorMap) => ReorderableSentenceTimelineListState(seekPosition, vocalistColorMap);
}

class ReorderableSentenceTimelineListState extends State<ReorderableSentenceTimelineList> {
  final AbsoluteSeekPosition seekPosition;
  final VocalistColorMap vocalistColorMap;
  late ScrollController _scrollController;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      key: const ValueKey("Reorderable List Vertical"),
      buildDefaultDragHandles: false,
      scrollController: verticalScrollController,
      onReorder: onReorder,
      onReorderEnd: (index) {
        isDragging = false;
      },
      children: List.generate(vocalistColorMap.length + 1, (index) {
        return AnimatedContainer(
          key: ValueKey('VocalistPanel_$index'),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: getReorderableListHeight(index),
          child: itemBuilder(context, index),
        );
      }),
    );
  }

  void onReorder(int oldIndex, int newIndex) {
    final Map<VocalistID, Vocalist> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap.map;
    if (newIndex > vocalistColorMap.length) {
      newIndex = vocalistColorMap.length;
    }

    if (oldIndex < vocalistColorMap.length && newIndex <= vocalistColorMap.length) {
      final key = vocalistColorMap.keys.elementAt(oldIndex);
      final value = vocalistColorMap.remove(key)!;

      final entries = vocalistColorMap.entries.toList();
      entries.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, MapEntry(key, value));

      vocalistColorMap
        ..clear()
        ..addEntries(entries);
    }

    setState(() {});
  }

  Widget itemBuilder(BuildContext context, int index) {
    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Duration audioDuration = musicPlayerService.audioDuration;
    final Map<VocalistID, Vocalist> vocalistColorMap = timingService.vocalistColorMap.map;
    final double intervalLength = timelinePaneProvider.intervalLength;
    final int intervalDuration = timelinePaneProvider.intervalDuration;

    if (index < vocalistColorMap.length) {
      final VocalistID vocalistID = vocalistColorMap.keys.toList()[index];

      final Color vocalistColor = Color(vocalistColorMap[vocalistID]!.color);
      final Color backgroundColor = adjustColorBrightness(vocalistColor, 0.3);

      final Widget borderLine = Container(
        width: 5,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.black,
              width: 5,
            ),
          ),
        ),
      );

      return Row(
        children: [
          GestureDetector(
            onTapDown: (details) {
              isDragging = true;
              setState(() {});
            },
            onTapUp: (details) {
              isDragging = false;
              setState(() {});
            },
            child: ReorderableDragStartListener(
              index: index,
              child: SvgIcon(
                assetName: 'assets/drag_handle.svg',
                iconColor: determineBlackOrWhite(backgroundColor),
                backgroundColor: vocalistColor,
                width: 20,
              ),
            ),
          ),
          SizedBox(
            width: 135,
            child: Container(alignment: Alignment.topLeft, child: cellVocalistPanel(index)),
          ),
          borderLine,
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey("Reorderable List Item ${vocalistID.id}"),
              controller: sentenceTimelineScrollController[vocalistID],
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: audioDuration.inMilliseconds * intervalLength / intervalDuration,
                child: cellSentenceTimeline(index),
              ),
            ),
          ),
        ],
      );
    } else {
      final Widget borderLine = Container(
        width: 5,
        height: 40,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.black,
              width: 5,
            ),
          ),
        ),
      );
      return Row(
        key: const ValueKey('AddVocalistButton'),
        children: [
          SizedBox(
            width: 155,
            height: getReorderableListHeight(index),
            child: cellAddVocalistButton(),
          ),
          borderLine,
          Expanded(child: cellAddVocalistButtonNeighbor()),
        ],
      );
    }
  }
}
