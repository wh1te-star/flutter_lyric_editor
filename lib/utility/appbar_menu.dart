import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'string_resource.dart';

AppBar buildAppBarWithMenu(BuildContext context, MusicPlayerService musicPlayerProvider, TimingService timingProvider) {
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
                openAudio(context, musicPlayerProvider);
                break;

              case StringResource.fileMenuCreateNewLyric:
                createNewLyric(context, timingProvider);
                break;

              case StringResource.fileMenuOpenLyric:
                openLyric(context, timingProvider);
                break;

              case StringResource.fileMenuExportLyric:
                exportLyric(context, timingProvider);
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

void openAudio(BuildContext context, MusicPlayerService musicPlayerProvider) async {
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
    musicPlayerProvider.requestInitAudio(file.path);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No file selected')),
    );
  }
}

void createNewLyric(BuildContext context, TimingService timingProvider) async {
  final XFile? file = await openFile(acceptedTypeGroups: [
    XTypeGroup(
      label: 'text',
      extensions: ['txt'],
      mimeTypes: ['text/plain'],
    )
  ]);

  if (file != null) {
    String rawText = await file.readAsString();
    timingProvider.requestInitLyric(rawText);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No file selected')),
    );
  }
}

void openLyric(BuildContext context, TimingService timingProvider) async {
  final XFile? file = await openFile(acceptedTypeGroups: [
    XTypeGroup(
      label: 'xlrc',
      extensions: ['xlrc'],
      mimeTypes: ['application/xml'],
    )
  ]);

  if (file != null) {
    String rawText = await file.readAsString();
    timingProvider.requestLoadLyric(rawText);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No file selected')),
    );
  }
}

void exportLyric(BuildContext context, TimingService timingProvider) async {
  const String fileName = 'example.xlrc';
  final FileSaveLocation? result = await getSaveLocation(suggestedName: fileName);
  if (result == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No file selected')),
    );
    return;
  }
  timingProvider.requestExportLyric(result);
}
