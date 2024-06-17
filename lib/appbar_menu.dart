import 'package:flutter/material.dart';
import 'package:lyric_editor/signal_structure.dart';
import 'package:rxdart/rxdart.dart';
import 'string_resource.dart';
import 'package:file_picker/file_picker.dart';

AppBar buildAppBarWithMenu(
    BuildContext context, PublishSubject<dynamic> masterSubject) {
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
          onChanged: (String? newValue) async {
            if (newValue == StringResource.fileMenuOpenAudio) {
              FilePickerResult? result = await FilePicker.platform.pickFiles();

              if (result != null) {
                PlatformFile file = result.files.first;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected file: ${file.name}')),
                );
                masterSubject.add(RequestInitAudio(file.path!));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No file selected')),
                );
              }
            } else {
              debugPrint('Selected Item: $newValue');
            }
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
