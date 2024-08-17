import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<List<String>> displayDialog(BuildContext context, List<String> texts) async {
  List<FocusNode> focusNodes = [];
  List<TextEditingController> controllers = [];
  List<Widget> textFields = [];
  texts.forEach((String text) {
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
  });

  WidgetsBinding.instance.addPostFrameCallback((_) {
    focusNodes[0].requestFocus();
  });

  List<String> resultTexts = [];
  void extractControllerTexts() {
    for (var controller in controllers) {
      resultTexts.add(controller.text);
      debugPrint(controller.text);
    }
  }

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Enter your text'),
        content: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter) {
                extractControllerTexts();
                Navigator.of(context).pop();
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
            child: Text('Cancel'),
            onPressed: () {
              debugPrint('Input cancelled.');
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () {
              extractControllerTexts();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );

  focusNodes.forEach((FocusNode node) {
    node.dispose();
  });
  controllers.forEach((TextEditingController controller) {
    controller.dispose();
  });

  return resultTexts;
}
