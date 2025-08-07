import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lyric_editor/audio_player/player_provider.dart';
import 'package:lyric_editor/screen/top_screen_load_lyric.dart';
import 'package:metadata_god/metadata_god.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _openFile(context, ref);
          },
          child: Text('Go to Second Screen'),
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context, WidgetRef ref) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'audio',
      extensions: <String>['mp3', 'flac', 'ogg', 'm4a'],
    );

    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) {
      return;
    }

    final playerNotifier = ref.read(playerProvider.notifier);

    try {
      final Uint8List fileBytes = await file.readAsBytes();
      final AudioSource audioSource = AudioSource.uri(
        Uri.dataFromBytes(fileBytes, mimeType: file.mimeType!),
      );

      Metadata metadata = await MetadataGod.readMetadata(file: file.path!);
      String? albumTitle = metadata.album;

      if (albumTitle != null) {
        await playerNotifier.setAndPlayAudioSource(audioSource);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoadLyricScreen(albumTitle)),
        );
      } else {
        final snackBar = SnackBar(
          content: Text('Album metadata not found.'),
          duration: const Duration(seconds: 3),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        content: Text('Error processing file: $e'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}