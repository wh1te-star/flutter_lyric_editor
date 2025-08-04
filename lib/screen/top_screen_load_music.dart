import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          /*
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SecondScreen()),
            );
          },
            */
          onPressed: () => _openFile(context),
          child: Text('Go to Second Screen'),
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context) async {
    // Open the file selection dialog.
    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        const XTypeGroup(label: 'All Files', extensions: <String>['*']),
      ],
    );

    // Check if a file was selected.
    if (file != null) {
      // Get the name of the selected file.
      final String fileName = file.name;

      // Create a SnackBar with the filename.
      final snackBar = SnackBar(
        content: Text('Selected file: $fileName'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            // Optional: You can add an action here.
          },
        ),
      );

      // Display the SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
