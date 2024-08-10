import 'dart:io';

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
                musicPlayerProvider.requestInitAudio();
                break;

              case StringResource.fileMenuCreateNewLyric:
                timingProvider.requestInitLyric();
                break;

              case StringResource.fileMenuOpenLyric:
                timingProvider.requestLoadLyric();
                break;

              case StringResource.fileMenuExportLyric:
                timingProvider.requestExportLyric();
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
