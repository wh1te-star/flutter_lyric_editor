import 'package:flutter/material.dart';

AppBar buildAppBarWithMenu(BuildContext context) {
  return AppBar(
    title: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () {
            // Handle button press
          },
          child: Text('Action 1'),
          style: TextButton.styleFrom(
            iconColor: Colors.white,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            // Handle button press
          },
          child: Text('Action 2'),
          style: TextButton.styleFrom(
            iconColor: Colors.white,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ],
    ),
  );
}
