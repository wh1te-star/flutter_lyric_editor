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
  late TextField startTimestampTextFiled;
  late TextField endTimestampTextFiled;

  List<bool> vocalistCheckValues = [];
  List<Widget> vocalistCheckboxList = [];

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

    startTimestampTextFiled = TextField(
      controller: startTimestampController,
      focusNode: startTimestampFocusNode,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
    );
    endTimestampTextFiled = TextField(
      controller: endTimestampController,
      focusNode: endTimestampFocusNode,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
    );

    List<String> vocalistNameList = timingService.vocalistColorMap.values.map((Vocalist vocalist) {
      return vocalist.name;
    }).toList();
    vocalistCheckValues = List<bool>.filled(vocalistNameList.length, false);
    vocalistCheckboxList = List.generate(vocalistNameList.length, (index) {
      return CheckboxListTile(
        title: Text(vocalistNameList[index]),
        value: vocalistCheckValues[index],
        onChanged: (bool? value) {
          setState(() {
            vocalistCheckValues[index] = value ?? false;
          });
        },
      );
    });

    /*
    checkboxValues = timingService.vocalistColorMap.entries
    editableTextController = TextEditingController();

    for (MapEntry<VocalistID, Vocalist> entry in .entries) {
      VocalistID vocalistID = entry.key;
      Vocalist vocalist = entry.value;

      FocusNode node = FocusNode();
      focusNodes.add(node);

      TextEditingController controller = TextEditingController();
      controllers.add(controller);

      controller.text = vocalist.name;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNodes[0].requestFocus();
    });
    */
  }

  @override
  void dispose() {
    startTimestampFocusNode.dispose();
    endTimestampFocusNode.dispose();
    startTimestampController.dispose();
    endTimestampController.dispose();
    /*
    for (var node in focusNodes) {
      node.dispose();
    }
    for (var controller in controllers) {
      controller.dispose();
    }
    editableTextController.dispose();
    */
    super.dispose();
  }

  void extractControllerTexts(List<String> resultTexts) {
    /*
    for (var controller in controllers) {
      resultTexts.add(controller.text);
    }
    resultTexts.add(editableTextController.text);
    */
  }

  @override
  Widget build(BuildContext context) {
    List<String> resultTexts = [];

    return AlertDialog(
      title: const Text('Snippet Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: startTimestampTextFiled,
                ),
                const Text("～"),
                Expanded(
                  child: endTimestampTextFiled,
                ),
              ],
            ),
            ...vocalistCheckboxList,
          ],
          /*
            const SizedBox(height: 10),
            TextField(
              controller: editableTextController,
              decoration: const InputDecoration(labelText: 'Editable Text'),
            ),
            const SizedBox(height: 10),
            Container(
              height: 50,
              color: Colors.blue,
            ),
            */
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
            extractControllerTexts(resultTexts);
            Navigator.of(context).pop(resultTexts);
          },
        ),
      ],
    );
  }

  bool isPowerOf2(int x) {
    return x > 0 && (x & (x - 1)) == 0;
  }
}
