import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:lyric_editor/screen/top_screen_load_lyric.dart';
import 'package:audiotags/audiotags.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _openFile(context);
          },
          //onPressed: () => _openFile(context),
          child: Text('Go to Second Screen'),
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context) async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'audio',
      extensions: <String>['mp3', 'flac', 'ogg', 'm4a'],
    );

    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) {
      return;
    }

    final String extension = file.name.split('.').last.toLowerCase();
    if (!['mp3', 'flac', 'ogg', 'm4a'].contains(extension)) {
      final snackBar = SnackBar(
        content: Text('Unsupported file type: $extension'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    Tag? tag = await AudioTags.read(file.path);
    String? title = tag?.title;
    String? trackArtist = tag?.trackArtist;
    String? album = tag?.album;
    String? albumArtist = tag?.albumArtist;

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoadLyricScreen(album!)));
  }
}
