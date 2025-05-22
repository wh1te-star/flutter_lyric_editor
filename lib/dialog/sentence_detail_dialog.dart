import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/diff_function/char_diff.dart';
import 'package:lyric_editor/diff_function/word_diff.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/utility/utility_functions.dart';

Future<void> displaySnippetDetailDialog(BuildContext context, SentenceID sentenceID, Sentence sentence) async {
  return await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return _SnippetDetailDialog(sentenceID: sentenceID, sentence: sentence);
    },
  );
}

class _SnippetDetailDialog extends ConsumerStatefulWidget {
  final SentenceID sentenceID;
  final Sentence sentence;

  const _SnippetDetailDialog({required this.sentenceID, required this.sentence});

  @override
  __SnippetDetailDialogState createState() => __SnippetDetailDialogState();
}

class __SnippetDetailDialogState extends ConsumerState<_SnippetDetailDialog> {
  late TimingService timingService;
  late final SentenceID sentenceID;
  late final Sentence sentence;

  late final FocusNode startTimeFocusNode;
  late final FocusNode endTimeFocusNode;
  late final FocusNode sentenceFocusNode;
  late final TextEditingController startTimeController;
  late final TextEditingController endTimeController;
  late final TextEditingController sentenceController;

  late final TextStyle textStyle = const TextStyle();

  List<bool> vocalistCheckValues = [];
  List<String> vocalistNameList = [];

  List<String> wordTexts = [];
  List<Vocalist> vocalists = [];

  late TableRow vocalistTabHeader;
  List<TableRow> vocalistTabRows = [];
  double checkboxCellWidth = 0.0;

  Map<VocalistID, List<bool>> segmentWiseVocalistCheckValues = {};

  late String currentSentence;

  @override
  void initState() {
    super.initState();

    timingService = ref.read(timingMasterProvider);

    sentenceID = widget.sentenceID;
    sentence = widget.sentence;

    startTimeFocusNode = FocusNode();
    endTimeFocusNode = FocusNode();
    sentenceFocusNode = FocusNode();
    startTimeController = TextEditingController();
    endTimeController = TextEditingController();
    sentenceController = TextEditingController();
    startTimeController.text = sentence.startTimestamp.toString();
    endTimeController.text = sentence.endTimestamp.toString();
    sentenceController.text = sentence.sentence;
    sentenceController.addListener(() {
      setState(() {});
    });

    vocalistCheckValues = [];
    vocalistNameList = timingService.vocalistColorMap.entries.where((entry) {
      int id = entry.key.id;
      return isPowerOf2(id);
    }).map((entry) {
      int singleVocalistID = entry.key.id;
      int snippetVocalistID = sentence.vocalistID.id;
      vocalistCheckValues.add(hasBit(snippetVocalistID, singleVocalistID));
      return entry.value.name;
    }).toList();

    Map<VocalistID, Vocalist> headerVocalists = {};
    for (int id = 1; id < pow(2, timingService.vocalistColorMap.length); id *= 2) {
      VocalistID vocalistID = sentence.vocalistID;
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
      segmentWiseVocalistCheckValues[vocalistID] = List.filled(sentence.sentenceSegments.length, true);
    }

    for (int i = 0; i < sentence.sentenceSegments.length; i++) {
      Word segment = sentence.sentenceSegments[i];
      wordTexts.add(segment.word);

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

      double padding = 4.0;
      double width = getSizeFromTextStyle(segment.word, textStyle).width + 2 * padding;
      if (width > checkboxCellWidth) {
        checkboxCellWidth = width;
      }

      vocalistTabRows.add(
        TableRow(
          children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: padding, right: padding),
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

    currentSentence = sentence.sentence;
  }

  @override
  void dispose() {
    startTimeFocusNode.dispose();
    endTimeFocusNode.dispose();
    sentenceFocusNode.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    sentenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sentence Details'),
      content: SizedBox(
        width: 300,
        child: DefaultTabController(
          length: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Overall'),
                  Tab(text: 'Vocalist'),
                  Tab(text: 'Sentence'),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    overallTab(),
                    vocalistTab(),
                    sentenceTab(),
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
            timingService = ref.read(timingMasterProvider);
            timingService.editSentence(sentenceID, sentenceController.text);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget overallTab() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Text("Start and End Time"),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: TextField(
                controller: startTimeController,
                focusNode: startTimeFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
              ),
            ),
            const Text("～"),
            Expanded(
              child: TextField(
                controller: endTimeController,
                focusNode: endTimeFocusNode,
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
    );
  }

  Widget vocalistTab() {
    return Column(children: [
      const SizedBox(height: 30),
      Table(
        border: TableBorder.all(),
        columnWidths: {
          0: const IntrinsicColumnWidth(),
          for (int i = 1; i <= vocalistTabRows.length; i++) i: FixedColumnWidth(checkboxCellWidth),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [vocalistTabHeader] + vocalistTabRows,
      )
    ]);
  }

  Widget sentenceTab() {
    return Column(
      children: [
        TextField(
          controller: sentenceController,
          focusNode: sentenceFocusNode,
          textAlign: TextAlign.center,
        ),
        sentenceComparison(currentSentence, sentenceController.text),
      ],
    );
  }

  Widget sentenceComparison(String before, String after) {
    TextStyle plainStyle = const TextStyle(color: Colors.black);
    TextStyle addStyle = const TextStyle(color: Colors.green);
    TextStyle deleteStyle = const TextStyle(color: Colors.red);
    TextStyle editStyle = const TextStyle(color: Colors.blue);

    CharDiff diff = CharDiff(before, after);

    List<Widget> wordDiffWidgets = diff.getLeastSegmentOne().map((WordDiff wordDiff) {
      String beforeStr = wordDiff.beforeStr;
      String afterStr = wordDiff.afterStr;
      TextStyle textStyle = plainStyle;
      if (beforeStr == "") {
        textStyle = addStyle;
      } else if (afterStr == "") {
        textStyle = deleteStyle;
      } else if (beforeStr != afterStr) {
        textStyle = editStyle;
      }
      return Column(children: [
        Text(wordDiff.beforeStr, style: textStyle),
        Text(wordDiff.afterStr, style: textStyle),
      ]);
    }).toList();

    return Row(
      children: wordDiffWidgets,
    );
  }

  bool isPowerOf2(int x) {
    return x > 0 && (x & (x - 1)) == 0;
  }

  bool hasBit(int number, int bit) {
    return number & bit != 0;
  }
}
