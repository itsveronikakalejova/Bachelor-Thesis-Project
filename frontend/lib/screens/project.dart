import 'package:flutter/material.dart';
import 'package:sesh/screens/groupChatScreen.dart';
import 'package:sesh/widgets/colors.dart';
import 'package:sesh/widgets/sideBar.dart';
import 'package:sesh/widgets/project_model.dart';
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
  List<Map<String, dynamic>> tasks = []; 
  bool isLoading = false;
  List<Map<String, dynamic>> projectFiles = [];
  String currentFileName = 'untitled.txt';

  @override
  void initState() {
    super.initState();
    _connectToSocket();
    _fetchProjectFiles();
    _fetchTasks(); 
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
      Uri.parse('http://localhost:3000/projects/${widget.projectId}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Project Data: $data");  // Debugging line
      return data['name']; // Return project name
    } else {
      return ''; // Return empty string if fetch fails
    }
  }

  Future<void> _fetchTasks() async {
    String projectName = await _fetchProjectName();
    
    if (projectName.isEmpty) {
      print("Project name is empty. Cannot fetch tasks.");
      return;
    }

    final url = Uri.parse('http://localhost:3000/tasks/tasks-by-project?projectName=$projectName');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        if (!mounted) return; // Skontrolujeme, či je widget stále nažive

        setState(() {
          tasks = data.map((task) => {
            'id': task['id'],
            'task_name': task['task_name'],
            'description': task['description'],
            'status': task['status'],
            'deadline': task['deadline'],
            'assigned_to': task['assigned_to']
          }).toList();
        });
      } else {
        print('Failed to load tasks: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching tasks: $error');
    }
  }


  Future<void> updateTaskStatus(String taskName, bool isDone) async {
    String newStatus = isDone ? 'done' : 'todo'; 

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/tasks/update-status'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'taskName': taskName,  // Poslanie názvu úlohy (backend vyhľadá ID)
          'newStatus': newStatus, // Poslanie nového stavu
        }),
      );

      if (response.statusCode == 200) {
        print('Task status updated successfully');

        // Aktualizuj lokálny stav v UI po úspešnom update
        setState(() {
          for (var task in tasks) {
            if (task['task_name'] == taskName) {
              task['status'] = newStatus;
            }
          }
        });
      } else {
        print('Failed to update task status: ${json.decode(response.body)['error']}');
      }
    } catch (error) {
      print('Error updating task status: $error');
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

  void cleanupAndNavigate(String route) {
    if (socket.connected) {
      socket.disconnect();
      socket.dispose();
    }
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pushNamed(context, route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 34, 34),
      drawer: SideBar(
        onProjectsTap: () => cleanupAndNavigate('/projects'),
        onChatsTap: () => cleanupAndNavigate('/chats'),
        onTasksTap: () => cleanupAndNavigate('/tasks'),
      ),


      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        title: FutureBuilder<String>(
        future: _fetchProjectName(), // Call the async method here
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();  // Display a loading indicator while waiting
          } else if (snapshot.hasError) {
            return const Text("Error loading project");
          } else if (snapshot.hasData) {
            return Text(
              snapshot.data!,  // Display the project name
              style: const TextStyle(color: Colors.black),
            );
          } else {
            return const Text("No Project Name");
          }
        },
      ),
        actions: [
          TextButton(
            onPressed: () {
              if (socket.connected) {
                socket.disconnect();
                socket.dispose();
              }
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
                // Add File and Save File buttons next to each other
                Row(
                  children: [
                    TextButton(
                      onPressed: _showAddFileDialog,
                      child: const Text(
                        'Add File',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    TextButton(
                      onPressed: saveTextInput,
                      child: const Text(
                        'Save File',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
                
                // Other buttons at the end
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
                      onPressed: () async {
                        String projectName = await _fetchProjectName();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupChatScreen(projectName: projectName, projectId: widget.projectId),
                          ),
                        );
                      },
                      child: const Text(
                        'Open Group Chat',
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
                  flex: 3,
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
                Expanded(
                  flex: 2,
                  child: Container(
                    color: myGreen,
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Tasks",
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: tasks.isEmpty
                              ? const Center(child: Text("No tasks!", style: TextStyle(color: Colors.black)))
                              : ListView.builder(
                                  itemCount: tasks.length,
                                  itemBuilder: (context, index) {
                                    bool isDone = tasks[index]['status'] == 'done';

                                    return Card(
                                      color: Colors.white,
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      child: ListTile(
                                        leading: Checkbox(
                                          value: isDone,
                                          onChanged: (bool? newValue) {
                                            if (newValue != null) {
                                              updateTaskStatus(tasks[index]['task_name'], newValue);
                                            }
                                          },
                                        ),
                                        title: GestureDetector(
                                          onTap: () {
                                            showTaskDetailsDialog(tasks[index]);
                                          },
                                          child: Text(
                                            tasks[index]['task_name'],
                                            style: const TextStyle(color: Colors.black),
                                          ),
                                        ),
                                        subtitle: GestureDetector(
                                          onTap: () {
                                            showTaskDetailsDialog(tasks[index]);
                                          },
                                          child: Text(
                                            tasks[index]['assigned_to'],
                                            style: const TextStyle(color: Color.fromARGB(255, 19, 102, 76)),
                                          ),
                                        ),
                                      ),

                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 8), // Medzera medzi zoznamom a tlačidlom
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text("Add Task", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: _showAddTaskDialog,
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
              '© Veronika Kalejová 2025',
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

  void showTaskDetailsDialog(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task['task_name']),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailText("Description", task['description'] ?? 'No description'),
              const SizedBox(height: 8),
              _buildDetailText("Status", task['status']),
              const SizedBox(height: 8),
              _buildDetailText("Deadline", task['deadline'] ?? 'No deadline'),
              const SizedBox(height: 8),
              _buildDetailText("Assigned to", task['assigned_to'] ?? 'Unassigned'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Pomocná funkcia na formátovanie riadkov s tučným názvom a bežnou hodnotou
  Widget _buildDetailText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Colors.black),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: value,
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() async {
    TextEditingController taskNameController = TextEditingController();
    TextEditingController taskDescriptionController = TextEditingController();
    TextEditingController taskDeadlineController = TextEditingController();
    String status = 'todo';
    String? selectedUser;

    List<String> privilegedUsers = await fetchPrivilegedUsers();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskNameController,
                  decoration: const InputDecoration(
                    labelText: 'Task Name',
                  ),
                ),
                TextField(
                  controller: taskDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                TextField(
                  controller: taskDeadlineController,
                  decoration: const InputDecoration(
                    labelText: 'Deadline (YYYY-MM-DD)',
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity, // Aby sa roztiahol na šírku dialógu
                  child: DropdownButtonFormField<String>(
                    value: selectedUser,
                    decoration: const InputDecoration(
                      labelText: 'Assign To',
                    ),
                    items: privilegedUsers.map((username) {
                      return DropdownMenuItem<String>(
                        value: username,
                        child: Text(username),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedUser = newValue;
                      });
                    },
                  ),
                ),
              ],
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
              onPressed: () async {
                String projectName = await _fetchProjectName();
                if (projectName.isEmpty || selectedUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please complete all fields.')),
                  );
                  return;
                }

                final response = await http.post(
                  Uri.parse('http://localhost:3000/tasks/add-task'),
                  headers: <String, String>{
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'task_name': taskNameController.text,
                    'description': taskDescriptionController.text,
                    'status': status,
                    'project_name': projectName,
                    'userName': selectedUser, // Priradený používateľ
                  }),
                );

                if (response.statusCode == 201) {
                  _fetchTasks();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to add task: ${json.decode(response.body)['error']}'),
                  ));
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  
  Future<List<String>> fetchPrivilegedUsers() async {
    // Získame názov projektu pomocou funkcie _fetchProjectName
    String projectName = await _fetchProjectName();

    if (projectName.isEmpty) {
      throw Exception('Project name not found');
    }

    // Získame zoznam používateľov s prístupom k projektu
    final response = await http.get(
      Uri.parse('http://localhost:3000/project/users-with-access?project_name=$projectName'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map<String>((user) => user['username'].toString()).toList();
    } else {
      throw Exception('Failed to fetch privileged users: ${response.body}');
    }
  }

}