import 'package:flutter/material.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sesh/widgets/shareDialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectPage extends StatefulWidget {
  final String token;
  final int userId;
  final String username;
  final int projectId;

  const ProjectPage({super.key, required this.token, required this.userId, required this.username, required this.projectId});

  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  late IO.Socket socket;
  final TextEditingController _contentController = TextEditingController();
  bool isLoading = false;
  List<Map<String, dynamic>> projectFiles = [];
  String currentFileName = 'text_input.txt';

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    _fetchProjectFiles();
  }

  void _connectToSocket() {
    socket = IO.io("http://localhost:3000", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });
    if (socket.connected) return; // Zabráni duplicite spojení

    socket = IO.io("http://localhost:3000", <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
    });

    socket.connect();

    socket.onConnect((_) {
      print("Connected to socket");
      socket.emit("join-document", widget.projectId);
    });

    socket.on("load-document", (data) {
      if (mounted) {
        setState(() {
          _contentController.text = data;
        });
      }
    });

    socket.on("update-document", (content) {
      if (mounted) {
        setState(() {
          _contentController.text = content;
        });
      }
    });

    socket.onDisconnect((_) {
      print("Socket disconnected");
    });

    socket.onError((error) {
      print("Socket error: $error");
    });
  }


  void _sendTextUpdate(String text) {
    socket.emit("update-document", {"docId": widget.projectId, "content": text});
  }

  Future<void> _fetchProjectFiles() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/projects/${widget.projectId}/files'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        projectFiles = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch project files')),
      );
    }
  }

  Future<void> _fetchFileContent(int fileId, String fileName) async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/projects/${widget.projectId}/files/$fileId'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _contentController.text = data['fileData'];
        currentFileName = fileName;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch file content')),
      );
    }
  }

  Future<String> _fetchProjectName() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/projects/${widget.projectId}/details'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Project Data: $data");  // Debugging line
      return data['name']; // Return project name
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch project name')),
      );
      return ''; // Return empty string if fetch fails
    }
  }

  Future<void> saveTextInput() async {
    final text = _contentController.text;

    final response = await http.post(
      Uri.parse('http://localhost:3000/projects/${widget.projectId}/saveText'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'text': text,
        'uploadedBy': widget.userId.toString(), // Use userId instead of username
        'fileName': currentFileName,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text input saved successfully')),
      );
      _fetchProjectFiles(); // Refresh the file list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save text input')),
      );
    }
  }


  Future<void> addFileToDatabase(String fileName) async {
    final text = _contentController.text;

    final response = await http.post(
      Uri.parse('http://localhost:3000/projects/${widget.projectId}/files'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'fileName': fileName,
        'fileType': 'text/x-c',
        'fileData': text,
        'uploadedBy': widget.userId.toString(), // Use userId instead of username
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File added successfully')),
      );
      _fetchProjectFiles(); // Refresh the file list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add file')),
      );
    }
  }

  void _showAddFileDialog() {
    final TextEditingController fileNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add File'),
          content: TextField(
            controller: fileNameController,
            decoration: const InputDecoration(
              labelText: 'File Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final fileName = fileNameController.text;
                if (fileName.isNotEmpty) {
                  addFileToDatabase(fileName);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File name cannot be empty')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    if (socket.connected) {
      socket.disconnect();
      socket.dispose();
    }
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _showAddFileDialog,
                  child: const Text(
                    'Add File',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // Compile and Run action
                      },
                      child: const Text(
                        'Compile and Run',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () async {
                        String projectName = await _fetchProjectName();
                        showShareDialog(context, projectName, "editor");
                      },
                      child: const Text(
                        'Share',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: saveTextInput,
                      child: const Text(
                        'Save File',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
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
                      ...projectFiles.map((file) => _buildProjectTile(context, file)).toList(),
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
                              fontFamily: 'Courier New',
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

  Widget _buildProjectTile(BuildContext context, Map<String, dynamic> file) {
    return Card(
      color: const Color.fromARGB(255, 214, 243, 243),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.black),
        title: Text(
          file['file_name'],
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
        onTap: () {
          _fetchFileContent(file['id'], file['file_name']);
        },
      ),
    );
  }
}