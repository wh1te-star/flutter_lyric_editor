import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist_color_map.dart';
import 'package:lyric_editor/pane/timeline_pane/reorderable_list.dart/sentence_timeline.dart';
import 'package:lyric_editor/pane/timeline_pane/reorderable_list.dart/vocalist_item.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';
import 'package:lyric_editor/utility/svg_icon.dart';
import 'package:lyric_editor/utility/utility_functions.dart';

class ReorderableSentenceTimelineList extends StatefulWidget {
  final AbsoluteSeekPosition seekPosition;
  final VocalistColorMap vocalistColorMap;
  final ScrollController verticalScrollController;
  final Map<VocalistID, ScrollController> horizontalScrollControllers;
  final Duration audioDuration;
  final double intervalLength;
  final int intervalDuration;

  const ReorderableSentenceTimelineList({
    required this.seekPosition,
    required this.vocalistColorMap,
    required this.verticalScrollController,
    required this.horizontalScrollControllers,
    required this.audioDuration,
    required this.intervalLength,
    required this.intervalDuration,
  });

  @override
  State<ReorderableSentenceTimelineList> createState() =>
      ReorderableSentenceTimelineListState();
}

class ReorderableSentenceTimelineListState
    extends State<ReorderableSentenceTimelineList> {
  final double normalHeight = 60.0;
  final double draggingHeight = 20.0;
  final double addVocalistDraggingHeight = 0.0;

  late ScrollController scrollController;
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    final Map<VocalistID, Vocalist> vocalistColorMap =
        widget.vocalistColorMap.map;

    return ReorderableListView(
      key: const ValueKey("Reorderable List Vertical"),
      buildDefaultDragHandles: false,
      scrollController: widget.verticalScrollController,
      onReorder: onReorder,
      onReorderEnd: (index) {
        isDragging = false;
      },
      itemExtentBuilder: (index, dimensions) {
        if (isDragging) {
          return draggingHeight;
        } else {
          return normalHeight;
        }
      },
      proxyDecorator: (child, index, animation) {
        return Container(
          key: ValueKey('ProxyAnimatedContainer_$index'),
          height: draggingHeight,
          child: Material(
            elevation: 6.0 * animation.value,
            color: Colors.transparent,
            child: child,
          ),
        );
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
    final Map<VocalistID, Vocalist> vocalistColorMap =
        widget.vocalistColorMap.map;
    if (newIndex > vocalistColorMap.length) {
      newIndex = vocalistColorMap.length;
    }

    if (oldIndex < vocalistColorMap.length &&
        newIndex <= vocalistColorMap.length) {
      final key = vocalistColorMap.keys.elementAt(oldIndex);
      final value = vocalistColorMap.remove(key)!;

      final entries = vocalistColorMap.entries.toList();
      entries.insert(
          newIndex > oldIndex ? newIndex - 1 : newIndex, MapEntry(key, value));

      vocalistColorMap
        ..clear()
        ..addEntries(entries);
    }

    setState(() {});
  }

  Widget itemBuilder(BuildContext context, int index) {
    final Map<VocalistID, Vocalist> vocalistColorMap =
        widget.vocalistColorMap.map;

    if (index < vocalistColorMap.length) {
      final VocalistID vocalistID = vocalistColorMap.keys.toList()[index];

      final String vocalistName = vocalistColorMap[vocalistID]!.name;
      final Color vocalistColor = Color(vocalistColorMap[vocalistID]!.color);
      final Color backgroundColor = adjustColorBrightness(vocalistColor, 0.3);

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
          VocalistItem(
            width: 140,
            height: getReorderableListHeight(index),
            name: vocalistName,
            vocalistColor: vocalistColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey("Reorderable List Item ${vocalistID.id}"),
              controller: widget.horizontalScrollControllers[vocalistID],
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: widget.audioDuration.inMilliseconds *
                    widget.intervalLength /
                    widget.intervalDuration,
                child: SentenceTimeline(vocalistID),
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        key: const ValueKey('AddVocalistButton'),
        children: [
          VocalistItem(
            width: 160,
            height: getReorderableListHeight(index),
            name: "+",
            vocalistColor: Colors.grey,
          ),
          const Expanded(child: ColoredBox(color: Colors.blueGrey)),
        ],
      );
    }
  }

  double getReorderableListHeight(int index) {
    final Map<VocalistID, Vocalist> vocalistColorMap =
        widget.vocalistColorMap.map;

    if (index >= vocalistColorMap.length) {
      if (isDragging) {
        return 0;
      } else {
        return 40;
      }
    }

    if (isDragging) {
      return 20.0;
    } else {
      return 60.0;
    }
  }

  double _getReorderableListHeight(int index) {
    final Map<VocalistID, Vocalist> vocalistColorMap =
        widget.vocalistColorMap.map;

    // Logic for your "Add Vocalist" button (the very last item)
    if (index >= vocalistColorMap.length) {
      if (isDragging) {
        return 0.0; // When dragging, the add button shrinks to 0 height
      } else {
        return normalHeight; // Normal height for the add button (40.0)
      }
    }

    // Logic for regular Vocalist items
    if (isDragging) {
      return draggingHeight; // When dragging, regular items shrink to 20.0
    } else {
      // Your original commented-out logic for dynamic height based on 'lanes'
      /*
    final Map<VocalistID, Map<SentenceID, Sentence>> sentencesForeachVocalist = timelinePaneProvider.sentencesForeachVocalist;
    final VocalistID vocalistID = vocalistColorMap.keys.toList()[index];
    if (sentencesForeachVocalist[vocalistID] == null) {
      return _draggingItemHeight; // If no sentences, perhaps keep it small
    } else {
      ShowHideTrackMap showHideTrackMap = ShowHideTrackMap(sentenceMap: timingService.sentenceMap, vocalistID: vocalistID);
      final int lanes = showHideTrackMap.getMaxTrackNumber();
      return _normalItemHeight * lanes; // Dynamic height based on lanes
    }
    */
      return normalHeight; // Default to normal height (60.0) if complex lane logic is not active
    }
  }
}
