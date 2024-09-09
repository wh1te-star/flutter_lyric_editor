import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<List<String>> displayDialog(BuildContext context, List<String> texts) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return _TextFieldDialog(texts: texts);
    },
  );
}

class _TextFieldDialog extends StatefulWidget {
  final List<String> texts;

  const _TextFieldDialog({required this.texts});

  @override
  __TextFieldDialogState createState() => __TextFieldDialogState();
}

class __TextFieldDialogState extends State<_TextFieldDialog> {
  late List<FocusNode> focusNodes;
  late List<TextEditingController> controllers;
  late List<Widget> textFields;

  @override
  void initState() {
    super.initState();
    focusNodes = [];
    controllers = [];
    textFields = [];

    for (String text in widget.texts) {
      FocusNode node = FocusNode();
      focusNodes.add(node);

      TextEditingController controller = TextEditingController();
      controllers.add(controller);

      controller.text = text;
      textFields.add(
        TextField(
          controller: controller,
          focusNode: node,
        ),
      );
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
    super.dispose();
  }

  void extractControllerTexts(List<String> resultTexts) {
    for (var controller in controllers) {
      resultTexts.add(controller.text);
      debugPrint(controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> resultTexts = [];

    return AlertDialog(
      title: const Text('Enter your text'),
      content: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              extractControllerTexts(resultTexts);
              Navigator.of(context).pop(resultTexts);
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: textFields,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            debugPrint('Input cancelled.');
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