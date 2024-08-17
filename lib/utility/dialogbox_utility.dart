import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void displayDialog(BuildContext context, TextEditingController controller, FocusNode node) {
  node.requestFocus();
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Enter your text'),
        content: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.enter) {
                print('Text entered: ${controller.text}');
                Navigator.of(context).pop();
              } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.of(context).pop();
              }
            }
          },
          child: TextField(
            controller: controller,
            focusNode: node,
            decoration: InputDecoration(hintText: "Type something here"),
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
              debugPrint('Text entered: ${controller.text}');
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  ).then((_) {});
}
