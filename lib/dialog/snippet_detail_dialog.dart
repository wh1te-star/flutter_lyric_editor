import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';

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

  List<bool> vocalistCheckValues = [];
  List<String> vocalistNameList = [];

  @override
  void initState() {
    super.initState();

    final TimingService timingService = ref.read(timingMasterProvider);

    startTimestampFocusNode = FocusNode();
    endTimestampFocusNode = FocusNode();
    startTimestampController = TextEditingController();
    endTimestampController = TextEditingController();
    startTimestampController.text = widget.snippet.startTimestamp.toString();
    endTimestampController.text = widget.snippet.endTimestamp.toString();

    vocalistCheckValues = [];
    vocalistNameList = timingService.vocalistColorMap.entries.where((entry) {
      int id = entry.key.id;
      return isPowerOf2(id);
    }).map((entry) {
      int singleVocalistID = entry.key.id;
      int snippetVocalistID = widget.snippet.vocalistID.id;
      vocalistCheckValues.add(hasBit(snippetVocalistID, singleVocalistID));
      return entry.value.name;
    }).toList();
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
      content: Container(
        width: 300,
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Overall'),
                  Tab(text: 'Segments'),
                ],
              ),
              Container(
                height: 300,
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        SizedBox(height: 30),
                      Text("Start and End Timestamp"),
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
                        SizedBox(height: 20),
                        Text("Vocalists"),
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
                      Text("A"),
                      Text("B"),
                      Text("C"),
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
