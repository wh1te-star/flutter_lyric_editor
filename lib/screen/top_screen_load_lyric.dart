import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to the previous screen
            Navigator.pop(context);
          },
          child: Text('Go Back'),
        ),
      ),
    );
  }
}