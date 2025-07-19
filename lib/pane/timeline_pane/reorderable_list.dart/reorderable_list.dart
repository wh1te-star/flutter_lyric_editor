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
    extends State<ReorderableSentenceTimelineList>
    with TickerProviderStateMixin {
  final double itemHeight = 60.0;
  //final double normalHeight = 60.0;
  //final double draggingHeight = 20.0;
  //final double addVocalistDraggingHeight = 0.0;
  //final Duration animationDuration = const Duration(milliseconds: 250);
  //final Curve animationCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<VocalistID, Vocalist> vocalistColorMap =
        widget.vocalistColorMap.map;

    return ReorderableListView(
      key: const ValueKey("Reorderable List Vertical"),
      buildDefaultDragHandles: false,
      scrollController: widget.verticalScrollController,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          onReorder(oldIndex, newIndex);
        });
      },
      //onReorderStart: (index) {},
      //onReorderEnd: (index) {},
      //proxyDecorator: (child, index, animation) {},
      //itemExtentBuilder: (index, dimensions) {},
      children: List.generate(vocalistColorMap.length + 1, (index) {
      ValueKey key = ValueKey("VocalistPanel_${VocalistID(0)}");
      if(index < vocalistColorMap.length) {
        VocalistID vocalistID = vocalistColorMap.keys.toList()[index];
        String vocalistName = vocalistColorMap[vocalistID]!.name;
        key = ValueKey('VocalistPanel_$vocalistName');
      }
        return Container(
          height: itemHeight,
          key: key,
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
          ReorderableDragStartListener(
            index: index,
            child: SvgIcon(
              assetName: 'assets/drag_handle.svg',
              iconColor: determineBlackOrWhite(backgroundColor),
              backgroundColor: vocalistColor,
              width: 20,
            ),
          ),
          VocalistItem(
            width: 140,
            height: itemHeight,
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
      // "Add Vocalist" button
      return Row(
        key: const ValueKey('AddVocalistButton'),
        children: [
          VocalistItem(
            width: 160,
            height: itemHeight,
            name: "+",
            vocalistColor: Colors.grey,
          ),
          const Expanded(child: ColoredBox(color: Colors.blueGrey)),
        ],
      );
    }
  }
}
