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
  late List<FocusNode> focusNodes;
  late List<TextEditingController> controllers;
  late List<bool> checkboxValues;
  late TextEditingController editableTextController;

  @override
  void initState() {
    super.initState();
    focusNodes = [];
    controllers = [];
    checkboxValues = List<bool>.filled(5, false);
    editableTextController = TextEditingController();

    final TimingService timingService = ref.read(timingMasterProvider);

    for (MapEntry<VocalistID, Vocalist> entry in timingService.vocalistColorMap.entries) {
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
  }

  @override
  void dispose() {
    for (var node in focusNodes) {
      node.dispose();
    }
    for (var controller in controllers) {
      controller.dispose();
    }
    editableTextController.dispose();
    super.dispose();
  }

  void extractControllerTexts(List<String> resultTexts) {
    for (var controller in controllers) {
      resultTexts.add(controller.text);
    }
    resultTexts.add(editableTextController.text);
  }

  @override
  Widget build(BuildContext context) {
    List<String> resultTexts = [];

    return AlertDialog(
      title: const Text('Enter your text'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...controllers.map((controller) => TextField(
                  controller: controller,
                  focusNode: focusNodes[controllers.indexOf(controller)],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                )),
            const SizedBox(height: 10),
            ...List.generate(checkboxValues.length, (index) {
              return CheckboxListTile(
                title: Text('Option ${index + 1}'),
                value: checkboxValues[index],
                onChanged: (bool? value) {
                  setState(() {
                    checkboxValues[index] = value ?? false;
                  });
                },
              );
            }),
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
          ],
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
}
