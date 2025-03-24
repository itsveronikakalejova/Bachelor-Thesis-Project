import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void showShareDialog(BuildContext context) {
  List<String> users = [];
  String selectedPerson = "";
  String selectedPrivilege = "Can View";

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse("http://localhost:3000/api/users"));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        users = List<String>.from(data);
        if (users.isNotEmpty) {
          selectedPerson = users.first;
        }
      } else {
        print("Error while fetching users: ${response.statusCode}");
      }
    } catch (e) {
      print("Error connecting to the server: $e");
    }
  }

  fetchUsers().then((_) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text("Share Project"),
              content: users.isEmpty
                  ? const Text("No users found")
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Add People:"),
                        DropdownButton<String>(
                          value: selectedPerson,
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              selectedPerson = newValue!;
                            });
                          },
                          items: users.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text("Select Privileges:"),
                        DropdownButton<String>(
                          value: selectedPrivilege,
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              selectedPrivilege = newValue!;
                            });
                          },
                          items: <String>["Can Edit", "Can View"]
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Project shared with $selectedPerson as $selectedPrivilege",
                                    ),
                                  ),
                                );
                                Navigator.of(context).pop();
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
  });
}