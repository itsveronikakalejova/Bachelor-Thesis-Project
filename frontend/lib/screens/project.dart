import 'package:flutter/material.dart';
import 'package:sesh/widgets/sideBar.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  _ProjectPageState createState() => _ProjectPageState();
}

  class _ProjectPageState extends State<ProjectPage> {
    final TextEditingController _contentController = TextEditingController();

    @override
    void dispose() {
      _contentController.dispose();
      super.dispose();
    }

    void _sendCodeToServer() async {
      final String code = _contentController.text;
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code field is empty!')),
        );
        return;
      }

      const String apiUrl = "http://127.0.0.1:2000/submit_code";

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"code": code}),
        );

        final responseData = jsonDecode(response.body);
        String message;

        if (response.statusCode == 200) {
          message = "${responseData['output']}";
        } else {
          message = "Error:\n${responseData['error']}";
        }

        _showOutputDialog(context, message);
      } catch (error) {
        _showOutputDialog(context, 'Error: $error');
      }
    }

  void _showOutputDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black, // Nastavenie čierneho pozadia
          title: const Text(
            "Compilation Output",
            style: TextStyle(color: Colors.green), // Modrý text pre názov
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white, // Modrý text pre výstup
                fontFamily: 'monospace', // Konzolový vzhľad písma
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.blue), // Modrý text pre tlačidlo
              ),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 34, 34),
      drawer: SideBar(
        onProjectsTap: () {
          Navigator.pushNamed(context, '/projects');
        },
        onChatsTap: () {
          Navigator.pushNamed(context, '/chats');
        },
        onTasksTap: () {
          Navigator.pushNamed(context, '/tasks');
        },
      ),
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        title: const Text(
          'IPC Project',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Go back ↩',
              style: TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            color: const Color.fromARGB(255, 214, 243, 243),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _sendCodeToServer,
                  child: const Text(
                    'Compile and Run',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    _showShareDialog(context);
                  },
                  child: const Text(
                    'Share',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 300,
                  color: const Color.fromARGB(255, 184, 233, 224),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16.0),
                      _buildProjectTile(context, 'program.c'),
                      const SizedBox(height: 8),
                      _buildProjectTile(context, 'game.c'),
                      const SizedBox(height: 8),
                      _buildProjectTile(context, 'maze.c'),
                      const SizedBox(height: 8),
                      _buildProjectTile(context, 'karel.c'),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: const Color.fromARGB(255, 55, 63, 59),
                    padding: const EdgeInsets.all(16.0),
                    alignment: Alignment.topLeft,
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type your code here...',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: const Color.fromARGB(255, 34, 34, 34),
            padding: const EdgeInsets.all(8.0),
            alignment: Alignment.center,
            child: const Text(
              '© Veronika Kalejová 2024',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectTile(BuildContext context, String projectName) {
    return Card(
      color: const Color.fromARGB(255, 214, 243, 243),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.black),
        title: Text(
          projectName,
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
        onTap: () {},
      ),
    );
  }
  
  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedPrivilege = 'Can View';
        String selectedPerson = 'Majo';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Share Project'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add People:'),
                  DropdownButton<String>(
                    value: selectedPerson,
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedPerson = newValue!;
                      });
                    },
                    items: <String>['Majo', 'Peto', 'Jano']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Privileges:'),
                  DropdownButton<String>(
                    value: selectedPrivilege,
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedPrivilege = newValue!;
                      });
                    },
                    items: <String>['Can Edit', 'Can View']
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
                                    'Project shared with $selectedPerson as $selectedPrivilege')),
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Share'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
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
}
