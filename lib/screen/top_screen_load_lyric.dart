import 'package:flutter/material.dart';

class LoadLyricScreen extends StatelessWidget {
  String album;
  LoadLyricScreen(this.album);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Screen'),
      ),
      body: Center(
        child: Column(
          children: [
            Text(album),
            ElevatedButton(
              onPressed: () {
                // Navigate back to the home screen
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
