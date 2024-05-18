import 'package:flutter/material.dart';
import 'string_resource.dart';

AppBar buildAppBarWithMenu(BuildContext context) {
  return AppBar(
    title: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        DropdownButton<String>(
          hint: const Text(StringResource.applicationMenu),
          onChanged: (String? newValue) {
            debugPrint('Selected Item: $newValue');
          },
          items:
              <String>[StringResource.applicationMenuExit].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        DropdownButton<String>(
          hint: const Text(StringResource.fileMenu),
          onChanged: (String? newValue) {
            debugPrint('Selected Item: $newValue');
          },
          items: <String>[
            StringResource.fileMenuOpenAudio,
            StringResource.fileMenuCreateNewLyric,
            StringResource.fileMenuOpenLyric,
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    ),
  );
}
