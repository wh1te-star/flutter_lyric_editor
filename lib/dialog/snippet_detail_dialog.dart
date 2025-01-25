import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/utility_functions.dart';

Future<List<String>> displaySnippetDetailDialog(BuildContext context, LyricSnippet snippet) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return _SnippetDetailDialog(snippet: snippet);
    },
  );
}

class _SnippetDetailDialog extends ConsumerStatefulWidget {
  final LyricSnippet snippet;

  const _SnippetDetailDialog({required this.snippet});

  @override
  __SnippetDetailDialogState createState() => __SnippetDetailDialogState();
}

class __SnippetDetailDialogState extends ConsumerState<_SnippetDetailDialog> {
  late FocusNode startTimestampFocusNode;
  late FocusNode endTimestampFocusNode;
  late TextEditingController startTimestampController;
  late TextEditingController endTimestampController;

  late TextStyle textStyle = TextStyle();

  List<bool> vocalistCheckValues = [];
  List<String> vocalistNameList = [];

  List<String> segmentTexts = [];
  List<Vocalist> vocalists = [];

  late TableRow vocalistTabHeader;
  List<TableRow> vocalistTabRows = [];
  double checkboxCellWidth = 0.0;

  Map<VocalistID, List<bool>> segmentWiseVocalistCheckValues = {};

  @override
  void initState() {
    super.initState();

    final TimingService timingService = ref.read(timingMasterProvider);
    final LyricSnippet snippet = widget.snippet;

    startTimestampFocusNode = FocusNode();
    endTimestampFocusNode = FocusNode();
    startTimestampController = TextEditingController();
    endTimestampController = TextEditingController();
    startTimestampController.text = snippet.startTimestamp.toString();
    endTimestampController.text = snippet.endTimestamp.toString();

    vocalistCheckValues = [];
    vocalistNameList = timingService.vocalistColorMap.entries.where((entry) {
      int id = entry.key.id;
      return isPowerOf2(id);
    }).map((entry) {
      int singleVocalistID = entry.key.id;
      int snippetVocalistID = snippet.vocalistID.id;
      vocalistCheckValues.add(hasBit(snippetVocalistID, singleVocalistID));
      return entry.value.name;
    }).toList();

    Map<VocalistID, Vocalist> headerVocalists = {};
    for (int id = 1; id < pow(2, timingService.vocalistColorMap.length); id *= 2) {
      VocalistID vocalistID = snippet.vocalistID;
      if ((vocalistID.id & id) != 0) {
        headerVocalists[vocalistID] = (timingService.vocalistColorMap[VocalistID(id)]!);
      }
    }
    List<Widget> headerVocalistWidgets = headerVocalists.values.map((Vocalist vocalist) {
      return Text(
        vocalist.name,
        textAlign: TextAlign.center,
        style: textStyle.copyWith(fontWeight: FontWeight.bold),
      );
    }).toList();

    vocalistTabHeader = TableRow(
      decoration: BoxDecoration(color: Colors.grey[300]),
      children: <Widget>[Text('word', textAlign: TextAlign.center, style: textStyle.copyWith(fontWeight: FontWeight.bold))] + headerVocalistWidgets,
    );

    for (MapEntry<VocalistID, Vocalist> entry in headerVocalists.entries) {
      VocalistID vocalistID = entry.key;
      Vocalist vocalist = entry.value;
      segmentWiseVocalistCheckValues[vocalistID] = List.filled(snippet.sentenceSegments.length, true);
    }

    for (int i = 0; i < snippet.sentenceSegments.length; i++) {
      SentenceSegment segment = snippet.sentenceSegments[i];
      segmentTexts.add(segment.word);

      List<Widget> segmentWiseVocalistCheckboxes = [];
      for (MapEntry<VocalistID, Vocalist> entry in headerVocalists.entries) {
        VocalistID vocalistID = entry.key;
        Vocalist vocalist = entry.value;

        segmentWiseVocalistCheckboxes.add(StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Checkbox(
              value: segmentWiseVocalistCheckValues[vocalistID]![i],
              onChanged: (bool? value) {
                setState(() {
                  segmentWiseVocalistCheckValues[vocalistID]![i] = value ?? false;
                });
              },
              activeColor: Color(vocalist.color),
            );
          },
        ));
      }

      double rightPadding = 4.0;
      double width = getSizeFromTextStyle(segment.word, textStyle).width + rightPadding;
      if (width > checkboxCellWidth) {
        checkboxCellWidth = width;
      }

      vocalistTabRows.add(
        TableRow(
          children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: rightPadding),
                  child: Text(
                    segment.word,
                    style: textStyle,
                    textAlign: TextAlign.right,
                  ),
                )
              ] +
              segmentWiseVocalistCheckboxes,
        ),
      );
    }
  }

  @override
  void dispose() {
    startTimestampFocusNode.dispose();
    endTimestampFocusNode.dispose();
    startTimestampController.dispose();
    endTimestampController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Snippet Details'),
      content: SizedBox(
        width: 300,
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Overall'),
                  Tab(text: 'Segments'),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 30),
                        const Text("Start and End Timestamp"),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: startTimestampController,
                                focusNode: startTimestampFocusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const Text("～"),
                            Expanded(
                              child: TextField(
                                controller: endTimestampController,
                                focusNode: endTimestampFocusNode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text("Vocalists"),
                        Column(
                          children: List.generate(vocalistNameList.length, (index) {
                            return CheckboxListTile(
                              title: Text(vocalistNameList[index]),
                              value: vocalistCheckValues[index],
                              onChanged: (bool? value) {
                                setState(() {
                                  vocalistCheckValues[index] = value ?? false;
                                });
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                    Column(children: [
                      const SizedBox(height: 30),
                      Table(
                        border: TableBorder.all(),
                        columnWidths: {
                          0: IntrinsicColumnWidth(),
                          for (int i = 1; i <= vocalistTabRows.length; i++) i: FixedColumnWidth(checkboxCellWidth),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [vocalistTabHeader] + vocalistTabRows,
                      )
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(vocalistCheckValues);
          },
        ),
      ],
    );
  }

  bool isPowerOf2(int x) {
    return x > 0 && (x & (x - 1)) == 0;
  }

  bool hasBit(int number, int bit) {
    return number & bit != 0;
  }
}
