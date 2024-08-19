import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'string_resource.dart';
import 'package:file_selector/file_selector.dart';

AppBar buildAppBarWithMenu(BuildContext context, PublishSubject<dynamic> masterSubject) {
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
                openAudio(context);
                break;

              case StringResource.fileMenuCreateNewLyric:
                masterSubject.add(RequestInitLyric());
                break;

              case StringResource.fileMenuOpenLyric:
                masterSubject.add(RequestLoadLyric());
                break;

              case StringResource.fileMenuExportLyric:
                masterSubject.add(RequestExportLyric());
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

void openAudio(BuildContext context) async {
  final musicPlayerProvider = Provider.of<MusicPlayerService>(context, listen: false);
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
          musicPlayerProvider.initAudio(file.path);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file selected')),
          );
        }
}