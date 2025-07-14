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
    extends State<ReorderableSentenceTimelineList> with TickerProviderStateMixin {
  final double normalHeight = 60.0;
  final double draggingHeight = 20.0;
  final double addVocalistDraggingHeight = 0.0; // This might need adjustment
  final Duration animationDuration = const Duration(milliseconds: 250);
  final Curve animationCurve = Curves.easeInOut;

  // Use a single bool for dragging state, and animate the height based on it
  bool _isReordering = false;

  // Animation controller for the height of all items
  late AnimationController _heightAnimationController;
  late Animation<double> _itemHeightAnimation;

  @override
  void initState() {
    super.initState();
    _heightAnimationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );

    // Initial state: normal height
    _itemHeightAnimation = Tween<double>(
      begin: normalHeight,
      end: normalHeight,
    ).animate(CurvedAnimation(parent: _heightAnimationController, curve: animationCurve));

    // Listen to animation changes to trigger rebuilds
    _heightAnimationController.addListener(() {
      // Rebuild the widget to apply the animated height from itemExtentBuilder
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _heightAnimationController.dispose();
    super.dispose();
  }

  // Helper to start the height animation
  void _startHeightAnimation(bool toShrink) {
    double targetHeight = toShrink ? draggingHeight : normalHeight;
    if (_itemHeightAnimation.value == targetHeight && _heightAnimationController.isCompleted) {
      // Avoid re-starting if already at target and completed
      return;
    }

    _itemHeightAnimation = Tween<double>(
      begin: _itemHeightAnimation.value,
      end: targetHeight,
    ).animate(CurvedAnimation(parent: _heightAnimationController, curve: animationCurve));

    _heightAnimationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final Map<VocalistID, Vocalist> vocalistColorMap = widget.vocalistColorMap.map;

    return ReorderableListView(
      key: const ValueKey("Reorderable List Vertical"),
      buildDefaultDragHandles: false,
      scrollController: widget.verticalScrollController,
      onReorderStart: (index) {
        setState(() {
          _isReordering = true;
        });
        _startHeightAnimation(true); // Shrink all items
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          onReorder(oldIndex, newIndex);
        });
      },
      onReorderEnd: (index) {
        setState(() {
          _isReordering = false;
        });
        _startHeightAnimation(false); // Expand all items back to normal
      },
      proxyDecorator: (child, index, animation) {
        // The proxyDecorator is for the visual representation of the dragging item.
        // Its height should reflect the desired draggingHeight directly.
        return Material(
          elevation: 6.0 * animation.value,
          color: Colors.transparent,
          child: SizedBox(
            height: 20.0, // This is the height of the dragging proxy
            width: MediaQuery.of(context).size.width,
            child: child,
          ),
        );
      },
      itemExtentBuilder: (index, dimensions) {
        // This determines the actual space each item occupies in the list.
        // It will animate based on _itemHeightAnimation.value
        return _itemHeightAnimation.value;
      },
      children: List.generate(vocalistColorMap.length + 1, (index) {
        return SizedBox(
          key: ValueKey('VocalistPanel_$index'), // Unique key is essential!
          // The height of the child itself should match the animated height from itemExtentBuilder
          height: _itemHeightAnimation.value,
          child: itemBuilder(context, index),
        );
      }),
    );
  }

  // The getReorderableListHeightForChild function is no longer needed
  // as _itemHeightAnimation directly drives the height for all list items.
  // The itemBuilder will receive this animated height via its parent SizedBox.

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
          // The GestureDetector on onTapDown/onTapUp for `isDragging` is no longer needed here,
          // as the reorder callbacks manage the _isReordering state and animation.
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
            // Pass the current animated height to VocalistItem
            height: _itemHeightAnimation.value,
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
            // Pass the current animated height to VocalistItem
            height: _itemHeightAnimation.value,
            name: "+",
            vocalistColor: Colors.grey,
          ),
          const Expanded(child: ColoredBox(color: Colors.blueGrey)),
        ],
      );
    }
  }
}