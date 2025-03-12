import 'package:flutter/material.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  late IO.Socket socket;
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  final String documentId = "project123"; // Unikátne ID dokumentu

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  void _connectToSocket() {
    socket = IO.io("http://localhost:3000", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    socket.connect();

    socket.onConnect((_) {
      socket.emit("join-document", documentId);
    });

    socket.on("load-document", (data) {
      setState(() {
        _contentController.text = data;
      });
    });

    socket.on("update-document", (content) {
      setState(() {
        _contentController.text = content;
      });
    });
  }

  void _sendTextUpdate(String text) {
    socket.emit("update-document", {"docId": documentId, "content": text});
  }

  @override
  void dispose() {
    _contentController.dispose();
    _inputController.dispose();
    socket.disconnect();
    super.dispose();
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
          style: TextStyle(color: Colors.black),
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
                  onPressed: () {
                    
                  },
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
                    child: Column(
                      children: [
                        Expanded(
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
                            onChanged: _sendTextUpdate,
                            textAlignVertical: TextAlignVertical.top,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                      ],
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
        return const AlertDialog(
          title: Text('Share Project'),
          content: Text('Sharing feature coming soon!'),
        );
      },
    );
  }
}
