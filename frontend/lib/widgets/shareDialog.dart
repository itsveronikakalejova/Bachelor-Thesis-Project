import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void showShareDialog(BuildContext context, String projectName, String privilege) {
  TextEditingController userController = TextEditingController();
  String statusMessage = '';

  // Share project function
  Future<void> shareProject(String userName) async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:3000/share"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          'projectName': projectName,
          'userName': userName,
          'privilege': privilege,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Project shared with $userName.")),
        );
      } else if (response.statusCode == 404) {
        statusMessage = "User not found";
      } else {
        statusMessage = "Failed to share project: ${response.statusCode}";
      }
    } catch (e) {
      statusMessage = "Error: $e";
    }
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: const Text("Share Project"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Enter Username:"),
                TextField(
                  controller: userController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                  ),
                ),
                if (statusMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      statusMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final userName = userController.text.trim();
                        if (userName.isNotEmpty) {
                          await shareProject(userName);
                          setDialogState(() {}); // refresh to show statusMessage if needed
                        }
                      },
                      child: const Text("Share"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Cancel"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
