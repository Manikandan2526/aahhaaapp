import 'package:flutter/material.dart';

showMessage(message, BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Message!"),
      content: Text(message.toString()),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
          child: const Text("Ok"),
        ),
      ],
    ),
  );
}

showLoader(String message, BuildContext context) async {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Please wait!"),
      content:  Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The loading indicator
          const  CircularProgressIndicator(),
          const  SizedBox(
              height: 15,
            ),
            // Some text
            Text(message)
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            //Navigator.of(context, rootNavigator: true).pop('dialog');
          },
          child: const Text(""),
        ),
      ],
    ),
  );
}
