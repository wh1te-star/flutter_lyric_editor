import 'package:flutter/material.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';

class ReorderableSentenceTimelineList extends StatefulWidget {
  final AbsoluteSeekPosition seekPosition;

  const ReorderableSentenceTimelineList({
    required this.seekPosition,
  });

  @override
  State<ReorderableSentenceTimelineList> createState() => ReorderableSentenceTimelineListState();
}

class ReorderableSentenceTimelineListState extends State<ReorderableSentenceTimelineList> {
  late ScrollController _scrollController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Use external controller if provided, otherwise create a new one
    _scrollController = widget.externalScrollController ?? ScrollController();
  }

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
}
