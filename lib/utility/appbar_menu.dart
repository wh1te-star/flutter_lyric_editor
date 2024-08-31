import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:rxdart/rxdart.dart';
import 'string_resource.dart';
import 'package:file_selector/file_selector.dart';

AppBar buildAppBarWithMenu(BuildContext context, PublishSubject<dynamic> masterSubject, MusicPlayerService musicPlayerService) {
  return AppBar(
    title: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        DropdownButton<String>(
          hint: const Text(StringResource.applicationMenu),
          onChanged: (String? newValue) {
            if (newValue == StringResource.applicationMenuExit) {
              if (Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android) {
                SystemNavigator.pop();
              } else {
                exit(0);
              }
            } else {
              debugPrint('Selected Item: $newValue');
            }
          },
          items: <String>[StringResource.applicationMenuExit].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        DropdownButton<String>(
          hint: const Text(StringResource.fileMenu),
          onChanged: (String? newValue) {
            switch (newValue) {
              case StringResource.fileMenuOpenAudio:
                openAudio(context, masterSubject, musicPlayerService);
                break;

              case StringResource.fileMenuCreateNewLyric:
                createNewLyric(context, masterSubject);
                break;

              case StringResource.fileMenuOpenLyric:
                openLyric(context, masterSubject);
                break;

              case StringResource.fileMenuExportLyric:
                exportLyric(context, masterSubject);
                break;

              default:
                debugPrint('Selected Item: $newValue');
                break;
            }
          },
          items: <String>[
            StringResource.fileMenuOpenAudio,
            StringResource.fileMenuCreateNewLyric,
            StringResource.fileMenuOpenLyric,
            StringResource.fileMenuExportLyric,
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

void openAudio(BuildContext context, PublishSubject<dynamic> masterSubject, MusicPlayerService musicPlayerSerivce) async {
  final XTypeGroup typeGroup = XTypeGroup(
    label: 'audio',
    extensions: ['mp3', 'wav', 'flac'],
    mimeTypes: ['audio/mpeg', 'audio/x-wav', 'audio/flac'],
  );
  final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

  if (file != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Selected file: ${file.name}'),
    ));
    musicPlayerSerivce.initAudio(file.path);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No file selected')),
    );
  }
}

void createNewLyric(BuildContext context, PublishSubject<dynamic> masterSubject) async {
  final XFile? file = await openFile(acceptedTypeGroups: [
    XTypeGroup(
      label: 'text',
      extensions: ['txt'],
      mimeTypes: ['text/plain'],
    )
  ]);

  if (file != null) {
    String rawText = await file.readAsString();
    masterSubject.add(RequestInitLyric(lyric: rawText));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No file selected')),
    );
  }
}

void openLyric(BuildContext context, PublishSubject<dynamic> masterSubject) async {
  final XFile? file = await openFile(acceptedTypeGroups: [
    XTypeGroup(
      label: 'xlrc',
      extensions: ['xlrc'],
      mimeTypes: ['application/xml'],
    )
  ]);

  if (file != null) {
    String rawLyricText = await file.readAsString();
    masterSubject.add(RequestLoadLyric(lyric: rawLyricText));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No file selected')),
    );
  }
}

void exportLyric(BuildContext context, PublishSubject<dynamic> masterSubject) async {
  const String fileName = 'example.xlrc';
  final FileSaveLocation? result = await getSaveLocation(suggestedName: fileName);
  if (result == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No file selected')),
    );
    return;
  }
  masterSubject.add(RequestExportLyric(path: result.path));
}
